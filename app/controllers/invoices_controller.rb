# frozen_string_literal: true

class InvoicesController < ApplicationController
  include SetEvent

  before_action :set_event, only: [:index, :new]
  skip_before_action :signed_in_user

  def index
    relation = @event.invoices
    authorize relation

    # The search query name was historically `search`. It has since been renamed
    # to `q`. This following line retains backwards compatibility.
    params[:q] ||= params[:search]

    # from events controller
    @invoices_in_transit = (relation.paid_v2.where(payout_id: nil)
      .where
      .not(payout_creation_queued_for: nil) +
      @event.invoices.joins(:payout)
      .where(invoice_payouts: { status: "in_transit" })
      .or(@event.invoices.joins(:payout).where(invoice_payouts: { status: "pending" })))
    amount_in_transit = @invoices_in_transit.sum(&:amount_paid)
    archived_unpaid = relation.unpaid.archived.sum(:item_amount)

    @stats = {
      # The calcluations for `total` and `unpaid` do not include archived invoices
      total: relation.sum(:item_amount) - archived_unpaid,
      # "paid" status invoices include manually paid invoices and
      # Stripe invoices that are paid, but for which the funds are in transit
      paid: relation.paid_v2.sum(:item_amount) - amount_in_transit,
      pending: amount_in_transit,
      unpaid: relation.unpaid.sum(:item_amount) - archived_unpaid,
    }

    case params[:filter]
    when "paid"
      relation = relation.paid_v2
    when "unpaid"
      relation = relation.unpaid
    when "archived"
      relation = relation.archived
    else
      relation = relation.unarchived
    end

    relation = relation.search_description(params[:q]) if params[:q].present?

    @invoices = relation.order(created_at: :desc)

    @sponsor = Sponsor.new(event: @event)
    @invoice = Invoice.new(sponsor: @sponsor)

    # @ma1ted: I have no clue how to use the above methods here.
    # Reimplementing logic is okay if you apolgise to every
    # future contributor. You can hold me to that.
    if @event.demo_mode? && params[:show_mock_data]&.downcase == "true"
      @invoices = []
      @stats = { total: 0, paid: 0, pending: 0, unpaid: 0 }

      # Generate mock invoices data
      (0..rand(10..30)).each do |_|
        # State is either sent, deposited, or overdue
        # Here, we'll only set deposited or overdue
        deposited = rand > 0.25
        invoice = OpenStruct.new(
          state: deposited ? "success" : "error",
          state_text: deposited ? "Deposited" : "Overdue",
          created_at: Faker::Date.between(from: 30.days.ago, to: Date.today),
          sponsor: OpenStruct.new(name: Faker::Name.name),
          item_amount: rand(1..100) * 100,
          local_hcb_code: OpenStruct.new(hashid: "")
        )
        @stats[:paid] += invoice.item_amount if deposited
        @stats[:unpaid] += invoice.item_amount unless deposited
        @stats[:total] += invoice.item_amount
        @invoices << invoice
      end
      # Sort by date descending
      @invoices.sort_by! { |invoice| invoice[:created_at] }.reverse!

      # Set the most recent 0-3 invoices to be sent
      (0..rand(-1..2)).each do |i|
        @invoices[i].state = "muted"
        @invoices[i].state_text = "Sent"
        @stats[:pending] += @invoices[i].item_amount
      end
    end
  end

  def new
    @sponsor = Sponsor.new(event: @event)
    @invoice = Invoice.new(sponsor: @sponsor)

    authorize @invoice
  end

  def create
    @event = Event.friendly.find(params[:event_id])

    authorize @event, policy_class: InvoicePolicy

    sponsor_attrs = filtered_params[:sponsor_attributes]

    due_date = Date.civil(filtered_params["due_date(1i)"].to_i,
                          filtered_params["due_date(2i)"].to_i,
                          filtered_params["due_date(3i)"].to_i)

    attrs = {
      event_id: params[:event_id],
      due_date: due_date,
      item_description: filtered_params[:item_description],
      item_amount: filtered_params[:item_amount],
      current_user: current_user,

      sponsor_id: sponsor_attrs[:id],
      sponsor_name: sponsor_attrs[:name],
      sponsor_email: sponsor_attrs[:contact_email],
      sponsor_address_line1: sponsor_attrs[:address_line1],
      sponsor_address_line2: sponsor_attrs[:address_line2],
      sponsor_address_city: sponsor_attrs[:address_city],
      sponsor_address_state: sponsor_attrs[:address_state],
      sponsor_address_postal_code: sponsor_attrs[:address_postal_code]
    }
    @invoice = ::InvoiceService::Create.new(attrs).run

    flash[:success] = "Invoice successfully created and emailed to #{@invoice.sponsor.contact_email}."

    redirect_to @invoice
  rescue => e
    Airbrake.notify(e)

    @event = Event.friendly.find(params[:event_id])
    @sponsor = Sponsor.new(event: @event)
    @invoice = Invoice.new(sponsor: @sponsor)

    redirect_to new_event_invoice_path(@event), flash: { error: e.message }
  end

  def show
    @invoice = Invoice.friendly.find(params[:id])
    authorize @invoice
    @hcb_code = HcbCode.find_or_create_by(hcb_code: @invoice.hcb_code)
    redirect_to hcb_code_path(@hcb_code.hashid)
  end

  def archive
    @invoice = Invoice.friendly.find(params[:invoice_id])

    authorize @invoice

    @invoice.archived_at = DateTime.now
    @invoice.archived_by = current_user

    if @invoice.save
      redirect_to @invoice
    else
      flash[:error] = "Something went wrong while trying to archive this invoice!"
      redirect_to @invoice
    end
  end

  def unarchive
    @invoice = Invoice.friendly.find(params[:invoice_id])

    authorize @invoice

    @invoice.archived_at = nil
    @invoice.archived_by = nil

    if @invoice.save
      flash[:success] = "Invoice has been un-archived."
      redirect_to @invoice
    else
      flash[:error] = "Something went wrong while trying to archive this invoice!"
      redirect_to @invoice
    end
  end

  private

  def filtered_params
    params.require(:invoice).permit(
      :due_date,
      :item_description,
      :item_amount,
      :sponsor_id,
      sponsor_attributes: policy(Sponsor).permitted_attributes
    )
  end

end
