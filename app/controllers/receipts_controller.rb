# frozen_string_literal: true

require "uri"
require "timeout"

class ReceiptsController < ApplicationController
  skip_after_action :verify_authorized, only: :upload # do not force pundit
  skip_before_action :signed_in_user, only: :upload
  before_action :set_paper_trail_whodunnit, only: :upload
  before_action :find_receiptable, only: [:upload, :link, :link_modal]

  def destroy
    @receipt = Receipt.find(params[:id])
    @receiptable = @receipt.receiptable
    authorize @receipt

    if @receipt.delete
      flash[:success] = "Deleted receipt"
      redirect_to @receiptable || my_inbox_path
    else
      flash[:error] = "Failed to delete receipt"
      redirect_to @receiptable
    end
  end

  def link
    params.require(:receipt_id)
    params.require(:receiptable_type)
    params.require(:receiptable_id)

    @receipt = Receipt.find(params[:receipt_id])

    authorize @receipt
    authorize @receiptable, policy_class: ReceiptablePolicy

    @receipt.update!(receiptable: @receiptable)

    if params[:show_link]
      flash[:success] = { text: "Receipt linked!", link: (hcb_code_path(@receiptable) if @receiptable.instance_of?(HcbCode)), link_text: "View" }
    else
      flash[:success] = "Receipt added!"
    end

    if params[:redirect_url]
      redirect_to params[:redirect_url]
    else
      redirect_back fallback_location: @receiptable.try(:hcb_code) || @receiptable
    end
  end

  def link_modal
    authorize @receiptable, policy_class: ReceiptablePolicy

    @receipts = Receipt.where(user: current_user, receiptable: nil)
    @suggested_receipt_ids = []

    if @receiptable.instance_of?(HcbCode)
      receipt_distances = @receipts.map do |receipt|
        {
          receipt: receipt,
          distance: SuggestedPairing.find_by(receipt: receipt, hcb_code: @receiptable).distance
        }
      end.sort_by { |receipt| receipt[:distance] }

      @receipts = receipt_distances.map { |receipt| receipt[:receipt] }
      @suggested_receipt_ids = receipt_distances.select { |receipt| receipt[:distance] < 40 }.map { |receipt| receipt[:receipt].id }
    end

    render :link_modal, layout: false
  end


  def upload
    params.require(:file)
    params.require(:upload_method)

    begin
      if @receiptable
        authorize @receiptable, policy_class: ReceiptablePolicy
      end
    rescue Pundit::NotAuthorizedError
      @has_valid_secret = @receiptable.instance_of?(HcbCode) && HcbCodeService::Receipt::SigningEndpoint.new.valid_url?(@receiptable.hashid, params[:s])

      raise unless @has_valid_secret
    end

    if params[:file] # Ignore if no files were uploaded
      receipts = params[:file].map do |file|
        ::ReceiptService::Create.new(
          receiptable: @receiptable,
          uploader: current_user,
          attachments: [file],
          upload_method: params[:upload_method]
        ).run!.to_a.first
      end

      if params[:show_link]
        flash[:success] = { text: "#{"Receipt".pluralize(params[:file].length)} added!", link: (hcb_code_path(@receiptable) if @receiptable.instance_of?(HcbCode)), link_text: "View" }
      else
        flash[:success] = "#{"Receipt".pluralize(params[:file].length)} added!"
      end
    end
  rescue => e
    notify_airbrake(e)

    flash[:error] = e.message
  ensure
    if params[:redirect_url] && receipts&.any?

      uri = URI.parse(params[:redirect_url])

      uri.query = URI.encode_www_form("uploaded_receipts[]": receipts.pluck(:id))

      redirect_to uri.to_s
    elsif params[:redirect_url]
      redirect_to params[:redirect_url]
    elsif @receiptable.is_a?(HcbCode) && @receiptable.stripe_card&.card_grant.present?
      redirect_to @receiptable.stripe_card.card_grant
    else
      referrer_url = URI.parse(request.referrer) rescue URI.parse(@receiptable&.try(:url) || url_for(@receiptable) || my_inbox_path)

      referrer_url.query = Rack::Utils.parse_nested_query(referrer_url.query)
        .merge({ "uploaded_receipts[]": receipts.pluck(:id) })
        .to_query

      redirect_to referrer_url.to_s
    end
  end

  private

  def find_receiptable
    if params[:receiptable_type].present? && params[:receiptable_id].present?
      @klass = params[:receiptable_type].constantize
      @receiptable = @klass.find(params[:receiptable_id])
    end
  end

end
