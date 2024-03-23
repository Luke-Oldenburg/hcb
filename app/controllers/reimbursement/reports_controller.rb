# frozen_string_literal: true

module Reimbursement
  class ReportsController < ApplicationController
    include SetEvent
    before_action :set_report_user_and_event, except: [:create, :quick_expense, :start]
    before_action :set_event, only: [:start]
    skip_before_action :signed_in_user, only: [:show, :start, :create]
    skip_after_action :verify_authorized, only: [:start]

    # POST /reimbursement_reports
    def create
      @event = Event.friendly.find(report_params[:event_id])
      user = User.find_or_create_by!(email: report_params[:email])
      @report = @event.reimbursement_reports.build(report_params.except(:email).merge(user:, inviter: current_user))

      authorize @report

      if @report.save
        if current_user && user == current_user
          redirect_to @report
        elsif admin_signed_in? || organizer_signed_in?
          redirect_to event_reimbursements_path(@event), flash: { success: "Report successfully created." }
        else
          # User not signed in (creating via public page)
          flash[:success] = "We've sent an invitation to your email."
          redirect_back(fallback_location: reimbursement_start_reimbursement_report_path(@event))
        end
      else
        redirect_to event_reimbursements_path(@event), flash: { error: @report.errors.full_messages.to_sentence }
      end
    end

    def quick_expense
      @event = Event.friendly.find(report_params[:event_id])
      @report = @event.reimbursement_reports.build({ user: current_user, inviter: current_user })

      authorize @report, :create?

      if @report.save
        @expense = @report.expenses.create!(amount_cents: 0)
        ::ReceiptService::Create.new(
          receiptable: @expense,
          uploader: current_user,
          attachments: params[:reimbursement_report][:file],
          upload_method: :quick_expense
        ).run!
        redirect_to reimbursement_report_path(@report, edit: @expense.id)
      else
        redirect_to event_reimbursements_path(@event), flash: { error: @report.errors.full_messages.to_sentence }
      end

    end

    def show
      if !signed_in?
        skip_authorization
        url_queries = { return_to: reimbursement_report_path(@report) }
        url_queries[:email] = params[:email] if params[:email]
        return redirect_to auth_users_path(url_queries), flash: { info: "To continue, please sign in with the email which received the invite." }
      end
      authorize @report
      @commentable = @report
      @comments = @commentable.comments
      @comment = Comment.new
      @use_user_nav = current_user == @user && !@event.users.include?(@user) && !admin_signed_in?
      @editing = params[:edit].to_i

    end

    def start
      if !@event.public_reimbursement_page_enabled?
        return not_found
      end
    end

    def edit
      authorize @report
    end

    def update
      authorize @report

      if @report.update(update_reimbursement_report_params)
        flash[:success] = "Report successfully updated."
        redirect_to @report
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # The following routes handle state changes for the reports.

    def draft

      authorize @report

      begin
        @report.mark_draft!
        flash[:success] = "Report marked as a draft, you can now make edits."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to @report
    end

    def submit
      authorize @report

      begin
        @report.mark_submitted!
        flash[:success] = "Report submitted for review. To make further changes, mark it as a draft."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to @report
    end

    def request_reimbursement

      authorize @report

      begin
        @report.mark_reimbursement_requested!
        flash[:success] = "Reimbursement requested; the HCB team will review the request promptly."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to @report
    end

    def admin_approve
      authorize @report

      begin
        @report.mark_reimbursement_approved!
        flash[:success] = "Reimbursement has been approved; the team & report creator will be notified."
      rescue => e
        flash[:error] = e.message
      end

      # ReimbursementJob::Nightly.perform_later

      redirect_to @report
    end

    def approve_all_expenses
      authorize @report

      begin
        @report.expenses.each do |expense|
          expense.mark_approved!
        end
        flash[:success] = "All expenses have been approved; the report creator will be notified."
      rescue => e
        flash[:error] = e.message
      end

      # ReimbursementJob::Nightly.perform_later

      redirect_to @report
    end

    def reject

      authorize @report

      begin
        @report.mark_rejected!
        flash[:success] = "Rejected & closed the report; no further changes can be made."
      rescue => e
        flash[:error] = e.message
      end

      redirect_to @report
    end

    # this is a custom method for creating a comment
    # that also makes the report as a draft.
    # - @sampoder

    def request_changes

      authorize @report

      comment_params = params.require(:comment).permit(:content, :admin_only, :action)

      if comment_params[:content].blank? && comment_params[:file].blank?
        flash[:success] = "We've sent this report back to #{@report.user.name} and marked it as a draft."
      else
        @comment = @report.comments.build(comment_params.merge(user: current_user))

        if @comment.save
          flash[:success] = "We've notified #{@report.user.name} of your requested changes."
        else
          flash[:error] = @report.errors.full_messages.to_sentence
          redirect_to @report and return
        end
      end

      begin
        @report.mark_draft!
      rescue => e
        flash[:error] = e.message
        redirect_to @report and return
      end

      redirect_to @report
    end

    def destroy

      authorize @report

      @report.destroy

      if organizer_signed_in?
        redirect_to event_reimbursements_path(@event)
      else
        redirect_to my_reimbursements_path
      end
    end

    private

    def set_report_user_and_event
      @report = Reimbursement::Report.find(params[:report_id] || params[:id])
      @event = @report.event
      @user = @report.user
    rescue ActiveRecord::RecordNotFound
      return redirect_to root_path, flash: { error: "We couldn’t find that report; it may have been deleted." }
    end

    def report_params
      params.require(:reimbursement_report).permit(:report_name, :maximum_amount, :event_id, :email, :invite_message).compact_blank
    end

    def update_reimbursement_report_params
      reimbursement_report_params = params.require(:reimbursement_report).permit(:report_name, :event_id, :maximum_amount).compact
      reimbursement_report_params.delete(:maximum_amount) unless current_user.admin? || @event.users.include?(current_user)
      reimbursement_report_params.delete(:maximum_amount) unless @report.draft?
      reimbursement_report_params
    end

  end
end
