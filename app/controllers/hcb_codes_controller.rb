# frozen_string_literal: true

class HcbCodesController < ApplicationController
  skip_before_action :signed_in_user, only: [:receipt, :attach_receipt, :show]

  def show
    @hcb_code = HcbCode.find_by(hcb_code: params[:id]) || HcbCode.find(params[:id])
    @event = @hcb_code.event

    hcb = @hcb_code.hcb_code
    hcb_id = @hcb_code.hashid

    authorize @hcb_code
  rescue Pundit::NotAuthorizedError => e
    raise unless @event.is_public?

    if @hcb_code.canonical_transactions.any?
      txs = TransactionGroupingEngine::Transaction::All.new(event_id: @event.id).run
      pos = txs.index { |tx| tx.hcb_code == hcb } + 1
      page = (pos.to_f / 100).ceil

      redirect_to event_path(@event, page: page, anchor: hcb_id)
    else
      redirect_to event_path(@event, anchor: hcb_id)
    end
  end

  def comment
    @hcb_code = HcbCode.find(params[:id])

    authorize @hcb_code

    attrs = {
      hcb_code_id: @hcb_code.id,
      content: params[:content],
      file: params[:file],
      admin_only: params[:admin_only],
      current_user: current_user
    }
    ::HcbCodeService::Comment::Create.new(attrs).run

    redirect_to params[:redirect_url]
  rescue => e
    redirect_to params[:redirect_url], flash: { error: e.message }
  end

  def receipt
    @hcb_code = HcbCode.find(params[:id])

    authorize @hcb_code

    params[:file]&.each do |file|
      attrs = {
        hcb_code_id: @hcb_code.id,
        file: file,
        upload_method: params[:upload_method],
        current_user: current_user
      }
      ::HcbCodeService::Receipt::Create.new(attrs).run
    end

    if params[:show_link]
      redirect_to params[:redirect_url], flash: { success: { text: "Receipt".pluralize(params[:file].length) + " added!", link: hcb_code_path(@hcb_code), link_text: "View" } }
    else
      redirect_to params[:redirect_url], flash: { success: "Receipt".pluralize(params[:file].length) + " added!" }
    end
  rescue => e
    Airbrake.notify(e)

    redirect_to params[:redirect_url], flash: { error: e.message }
  end

  def attach_receipt
    @hcb_code = HcbCode.find(params[:id])
    @event = @hcb_code.event

    authorize @hcb_code

  rescue Pundit::NotAuthorizedError
    unless (@hcb_code.date > 10.days.ago) && HcbCodeService::Receipt::SigningEndpoint.new.valid_url?(@hcb_code.hashid, params[:s])
      raise
    end
  end

  include HcbCodeHelper # for disputed_transactions_airtable_form_url
  def dispute
    @hcb_code = HcbCode.find(params[:id])

    authorize @hcb_code

    can_dispute, error_reason = ::HcbCodeService::CanDispute.new(hcb_code: @hcb_code).run

    if can_dispute
      redirect_to disputed_transactions_airtable_form_url(embed: false, hcb_code: @hcb_code, user: @current_user)
    else
      redirect_to @hcb_code, flash: { error: error_reason }
    end
  end

end
