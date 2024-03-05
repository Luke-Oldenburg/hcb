# frozen_string_literal: true

class ReimbursementMailer < ApplicationMailer
  def invitation
    @report = params[:report]

    mail to: @report.user.email, subject: "Get reimbursed by #{@report.event.name} for #{@report.name}", from: hcb_email_with_name_of(@report.event)
  end

  def reimbursement_approved
    @report = params[:report]

    mail to: @report.user.email, subject: "#{@report.name}: Reimbursement Approved", from: hcb_email_with_name_of(@report.event)
  end

  def rejected
    @report = params[:report]

    mail to: @report.user.email, subject: "#{@report.name}: Reimbursement Rejected", from: hcb_email_with_name_of(@report.event)
  end

  def changes_requested
    @report = params[:report]

    mail to: @report.user.email, subject: "#{@report.name}: Changes Requested", from: hcb_email_with_name_of(@report.event)
  end

  def review_requested
    @report = params[:report]

    mail to: @report.event.users.pluck(:email).excluding(@report.user.email), subject: "#{@report.name}: Review Requested"
  end

  def expense_approved
    @report = params[:report]
    @expense = params[:expense]

    mail to: @report.user.email, subject: "An update on your reimbursement for #{@expense.memo}", from: hcb_email_with_name_of(@report.event)
  end

end
