# frozen_string_literal: true

module SystemEventService
  module Write
    class SettledTransactionCreated
      NAME = "settledTransactionCreated"

      def initialize(canonical_transaction:)
        @canonical_transaction = canonical_transaction
      end

      def run
        ::SystemEventService::Create.new(
          name:,
          properties:
        ).run
      end

      private

      def name
        NAME
      end

      def properties
        {
          canonical_transaction: {
            id: @canonical_transaction.id,
            date: @canonical_transaction.date,
            memo: @canonical_transaction.memo,
            amount_cents: @canonical_transaction.amount_cents
          }
        }
      end

    end
  end
end
