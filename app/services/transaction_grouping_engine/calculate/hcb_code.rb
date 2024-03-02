# frozen_string_literal: true

module TransactionGroupingEngine
  module Calculate
    class HcbCode
      # PATTERN: HCB-TRANSACTION/TYPE/SOURCE-UNIQUEIDENTIFIER
      #
      HCB_CODE = "HCB"
      SEPARATOR = "-"
      UNKNOWN_CODE = "000"
      # 001 — This type code exists in production to group transactions under
      # `000` while preventing from the TX Engine from trying to re-group them.
      # For context, `TransactionGroupingEngineJob::Nightly` will try to group
      # any CanonicalTransactions with a `000`. `001` was used to manually group
      # transactions together during an incident.
      INVOICE_CODE = "100"
      DONATION_CODE = "200"
      PARTNER_DONATION_CODE = "201"
      ACH_TRANSFER_CODE = "300"
      CHECK_CODE = "400"
      INCREASE_CHECK_CODE = "401"
      CHECK_DEPOSIT_CODE = "402"
      DISBURSEMENT_CODE = "500"
      STRIPE_CARD_CODE = "600"
      STRIPE_FORCE_CAPTURE_CODE = "601"
      BANK_FEE_CODE = "700"
      INCOMING_BANK_FEE_CODE = "701" # short-lived and deprecated
      FEE_REVENUE_CODE = "702"
      ACH_PAYMENT_CODE = "800" # ALSO short-lived and deprecated
      OUTGOING_FEE_REIMBURSEMENT_CODE = "900" # Note: many old fee reimbursements are still grouped under HCB-000

      def initialize(canonical_transaction_or_canonical_pending_transaction:)
        @ct_or_cp = canonical_transaction_or_canonical_pending_transaction
      end

      def run
        return increase_check_hcb_code if increase_check
        return unknown_hcb_code if @ct_or_cp.is_a?(CanonicalTransaction) && @ct_or_cp.raw_increase_transaction&.increase_account_number.present? # Don't attempt to group transactions posted to an org's account/routing number
        return short_code_hcb_code if has_short_code?
        return invoice_hcb_code if invoice
        return donation_hcb_code if donation
        return partner_donation_hcb_code if partner_donation
        return ach_transfer_hcb_code if ach_transfer
        return check_hcb_code if check
        return check_deposit_hcb_code if check_deposit
        return disbursement_hcb_code if disbursement
        return stripe_card_hcb_code if raw_stripe_transaction
        return stripe_card_hcb_code_pending if raw_pending_stripe_transaction
        return ach_payment_hcb_code if ach_payment
        return outgoing_fee_reimbursement_hcb_code if outgoing_fee_reimbursement?

        unknown_hcb_code
      end

      private

      def has_short_code?
        @ct_or_cp.try(:short_code).present?
      end

      def short_code_hcb_code
        ::HcbCode.find_by(short_code: @ct_or_cp.short_code)&.hcb_code || unknown_hcb_code
      end

      def invoice_hcb_code
        [
          HCB_CODE,
          INVOICE_CODE,
          invoice.id
        ].join(SEPARATOR)
      end

      def invoice
        @invoice ||= @ct_or_cp.invoice
      end

      def donation_hcb_code
        [
          HCB_CODE,
          DONATION_CODE,
          donation.id
        ].join(SEPARATOR)
      end

      def donation
        @donation ||= @ct_or_cp.donation
      end

      def partner_donation_hcb_code
        [
          HCB_CODE,
          PARTNER_DONATION_CODE,
          partner_donation.id
        ].join(SEPARATOR)
      end

      def partner_donation
        @partner_donation ||= @ct_or_cp.partner_donation
      end

      def ach_transfer_hcb_code
        [
          HCB_CODE,
          ACH_TRANSFER_CODE,
          ach_transfer.id
        ].join(SEPARATOR)
      end

      def ach_transfer
        @ach_transfer ||= @ct_or_cp.ach_transfer
      end

      def check_hcb_code
        [
          HCB_CODE,
          CHECK_CODE,
          check.id
        ].join(SEPARATOR)
      end

      def check
        @check ||= @ct_or_cp.check
      end

      def increase_check_hcb_code
        [
          HCB_CODE,
          INCREASE_CHECK_CODE,
          increase_check.id
        ].join(SEPARATOR)
      end

      def increase_check
        @increase_check ||= @ct_or_cp.increase_check
      end

      def check_deposit_hcb_code
        [
          HCB_CODE,
          CHECK_DEPOSIT_CODE,
          check_deposit.id
        ].join(SEPARATOR)
      end

      def check_deposit
        @check_deposit ||= @ct_or_cp.check_deposit
      end

      def disbursement_hcb_code
        [
          HCB_CODE,
          DISBURSEMENT_CODE,
          disbursement.id
        ].join(SEPARATOR)
      end

      def disbursement
        @disbursement ||= @ct_or_cp.disbursement
      end

      def stripe_card_hcb_code
        return stripe_force_capture_hcb_code unless @ct_or_cp.remote_stripe_iauth_id.present?

        [
          HCB_CODE,
          STRIPE_CARD_CODE,
          @ct_or_cp.remote_stripe_iauth_id
        ].join(SEPARATOR)
      end

      def stripe_force_capture_hcb_code
        [
          HCB_CODE,
          STRIPE_FORCE_CAPTURE_CODE,
          @ct_or_cp.id
        ].join(SEPARATOR)
      end

      def raw_stripe_transaction
        @raw_stripe_transaction ||= @ct_or_cp.raw_stripe_transaction
      end

      def stripe_card_hcb_code_pending
        raise ArgumentError, "stripe_card_hcb_code requires remote stripe iauth id" unless @ct_or_cp.remote_stripe_iauth_id.present?

        [
          HCB_CODE,
          STRIPE_CARD_CODE,
          @ct_or_cp.remote_stripe_iauth_id
        ].join(SEPARATOR)
      end

      def raw_pending_stripe_transaction
        @raw_pending_stripe_transaction ||= @ct_or_cp.raw_pending_stripe_transaction
      end

      def ach_payment_hcb_code
        [
          HCB_CODE,
          ACH_PAYMENT_CODE,
          ach_payment.id
        ].join(SEPARATOR)
      end

      def ach_payment
        @ct_or_cp.try :ach_payment
      end

      def outgoing_fee_reimbursement_hcb_code
        [
          HCB_CODE,
          OUTGOING_FEE_REIMBURSEMENT_CODE,
          @ct_or_cp.date.strftime("%G_%V"),
        ].join(SEPARATOR)
      end

      def outgoing_fee_reimbursement?
        @ct_or_cp.memo.downcase.include?("stripe fee reimbursement")
      end

      def unknown_hcb_code
        [
          HCB_CODE,
          UNKNOWN_CODE,
          @ct_or_cp.id
        ].join(SEPARATOR)
      end

    end
  end
end
