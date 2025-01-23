# frozen_string_literal: true

module StripeAuthorizationService
  module Webhook
    class HandleIssuingAuthorizationRequest
      attr_reader :declined_reason

      def initialize(stripe_event:)
        @stripe_event = stripe_event
      end

      def run
        approve?
      end

      private

      def auth
        @stripe_event[:data][:object]
      end

      def auth_id
        auth[:id]
      end

      def amount_cents
        auth[:pending_request][:amount]
      end

      def stripe_card_id
        auth[:card][:id]
      end

      def card
        @card ||= StripeCard.includes(:card_grant).find_by(stripe_id: stripe_card_id)
      end

      def card_balance_available
        @card_balance_available ||= card.balance_available
      end

      def event
        card.event
      end

      def decline_with_reason!(reason)
        @declined_reason = reason
        set_metadata!(declined_reason: reason)

        false
      end

      def cash_withdrawal?
        auth[:merchant_data][:category_code] == "6011"
      end

      def approve?
        allowed_categories = card&.card_grant&.allowed_categories
        allowed_merchants = card&.card_grant&.allowed_merchants
        keyword_lock = card&.card_grant&.keyword_lock

        if (allowed_categories.present? || allowed_merchants.present? || keyword_lock.present?) && !((allowed_categories.present? && allowed_categories.include?(auth[:merchant_data][:category])) ||
              (allowed_merchants.present? && allowed_merchants.include?(auth[:merchant_data][:network_id])) ||
              (keyword_lock.present? && Regexp.new(keyword_lock).match?(auth[:merchant_data][:name])))
           return decline_with_reason!("merchant_not_allowed")

        end

        return decline_with_reason!("inadequate_balance") if card_balance_available < amount_cents

        return decline_with_reason!("cash_withdrawals_not_allowed") if cash_withdrawal? && !card.cash_withdrawal_enabled?

        set_metadata!

        true
      end

      def set_metadata!(additional = {})
        return if Rails.env.test?

        default_metadata = {
          current_balance_available: card_balance_available,
        }

        StripeService::Issuing::Authorization.update(
          auth_id,
          { metadata: default_metadata.deep_merge(additional) }
        )
      end

    end
  end
end
