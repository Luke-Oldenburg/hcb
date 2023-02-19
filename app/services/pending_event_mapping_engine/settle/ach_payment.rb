# frozen_string_literal: true

module PendingEventMappingEngine
  module Settle
    class AchPayment
      def run
        unsettled.find_each(batch_size: 100) do |cpt|
          # 1. Wait for 2 canonical transactions (payout and fee reimbursement)
          if cpt.local_hcb_code.canonical_transactions.length == 2
            ct = cpt.local_hcb_code.canonical_transactions.first

            CanonicalPendingTransactionService::Settle.new(
              canonical_transaction: ct,
              canonical_pending_transaction: cpt
            ).run!
          end
        end
      end

      private

      def unsettled
        CanonicalPendingTransaction.unsettled.ach_payment
      end

    end
  end
end
