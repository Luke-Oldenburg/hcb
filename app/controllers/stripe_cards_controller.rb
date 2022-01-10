# frozen_string_literal: true

class StripeCardsController < ApplicationController
  def index
    @cards = StripeCard.all
    authorize @cards
  end

  # async frame for shipment tracking
  def shipping
    if params[:event_id] # event card overview page
      @event = Event.friendly.find(params[:event_id])
      authorize @event
      @stripe_cards = @event.stripe_cards.physical_shipping
    else # my cards page
      @stripe_cards = current_user.stripe_cards.physical_shipping
      skip_authorization # do not force pundit
    end
    render :shipping, layout: false
  end

  def freeze
    @card = StripeCard.find(params[:stripe_card_id])
    authorize @card

    if @card.freeze!
      flash[:success] = "Card frozen"
      redirect_to @card
    else
      render "show"
    end
  end

  def defrost
    @card = StripeCard.find(params[:stripe_card_id])
    authorize @card

    if @card.defrost!
      flash[:success] = "Card defrosted"
      redirect_to @card
    else
      render "show"
    end
  end

  def show
    @card = StripeCard.includes(:event, :user).find(params[:id])

    authorize @card

    @event = @card.event
  end

  def new
    @event = Event.friendly.find(params[:event_id])

    authorize @event, :user_or_admin?, policy_class: EventPolicy
  end

  def create
    event = Event.friendly.find(params[:stripe_card][:event_id])
    authorize event, :user_or_admin?, policy_class: EventPolicy

    sc = params[:stripe_card]
    attrs = {
      current_user: current_user,
      event_id: event.id,
      card_type: sc[:card_type],
      stripe_shipping_name: sc[:stripe_shipping_name],
      stripe_shipping_address_city: sc[:stripe_shipping_address_city],
      stripe_shipping_address_state: sc[:stripe_shipping_address_state],
      stripe_shipping_address_line1: sc[:stripe_shipping_address_line1],
      stripe_shipping_address_line2: sc[:stripe_shipping_address_line2],
      stripe_shipping_address_postal_code: sc[:stripe_shipping_address_postal_code],
    }
    ::StripeCardService::Create.new(attrs).run

    redirect_to event_cards_overview_path(event_id: event.id), flash: { success: "Card was successfully created." }
  rescue => e
    Airbrake.notify(e)

    redirect_to event_cards_new_path(event_id: event.id), flash: { error: e.message }
  end

  private

  def suggested(field)
    return nil unless current_user

    ecr = EmburseCardRequest.where(creator_id: current_user&.id)
    case field
    when :phone_number
      current_user.phone_number
    when :name
      current_user.full_name
    when :line1
      current_user&.stripe_cardholder&.stripe_billing_address_line1 ||
        ecr&.last&.shipping_address_street_one
    when :line2
      current_user&.stripe_cardholder&.stripe_billing_address_line2 ||
        ecr&.last&.shipping_address_street_two
    when :city
      current_user&.stripe_cardholder&.stripe_billing_address_city ||
        ecr&.last&.shipping_address_city
    when :state
      current_user&.stripe_cardholder&.stripe_billing_address_state ||
        ecr&.last&.shipping_address_state
    when :postal_code
      current_user&.stripe_cardholder&.stripe_billing_address_postal_code ||
        ecr&.last&.shipping_address_zip
    when :country
      current_user&.stripe_cardholder&.stripe_billing_address_country ||
        ("US" if ecr.any?)
    else
      nil
    end
  end

  # Only allow a trusted parameter "white list" through.
  def stripe_card_params
    params.require(:stripe_card).permit(
      :event_id,
      :card_type,
      :stripe_cardholder_id,
      :stripe_shipping_name,
      :stripe_shipping_address_city,
      :stripe_shipping_address_line1,
      :stripe_shipping_address_postal_code,
      :stripe_shipping_address_line2,
      :stripe_shipping_address_state
    )
  end

end
