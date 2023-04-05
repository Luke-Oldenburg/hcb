# frozen_string_literal: true

module DonationService
  class Refund
    include ::Shared::Selenium::LoginToSvb
    include ::Shared::Selenium::TransferFromFsOperatingToFsMain
    include ::Shared::Selenium::TransferFromFsMainToFsOperating

    def initialize(donation_id:)
      @donation_id = donation_id
    end

    def run
      login_to_svb!

      ActiveRecord::Base.transaction do
        # 1. Mark refunded
        donation.mark_refunded!

        # 2. Un-front all pending transaction associated with this donation
        donation.canonical_pending_transactions.update_all(fronted: false)

        raise ArgumentError, "production only" unless Rails.env.production?

        # 3. Process remotely
        ::Partners::Stripe::Refunds::Create.new(payment_intent_id:).run

        # 4. Transfer on SVB
        transfer_from_fs_main_to_fs_operating!(amount_cents:, memo:) # make the transfer on remote bank similar to monthly fee service
      end

      sleep 5

      driver.quit
    end

    private

    def amount_cents
      donation.amount
    end

    def memo
      "#{donation.hcb_code} REFUND"
    end

    def donation
      @donation ||= ::Donation.find(@donation_id)
    end

    def payment_intent_id
      donation.stripe_payment_intent_id
    end

  end
end
