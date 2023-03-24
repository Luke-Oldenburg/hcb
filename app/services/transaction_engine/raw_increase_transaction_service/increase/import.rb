# frozen_string_literal: true

module TransactionEngine
  module RawIncreaseTransactionService
    module Increase
      class Import
        def initialize(start_date: 1.month.ago)
          @start_date = start_date
        end

        def run
          params = {
            account_id: IncreaseService::AccountIds::FS_MAIN,
            "created_at.on_or_after": @start_date.iso8601
          }

          ::Increase::Transactions.list(params) do |transactions|
            # For each transaction in the page...
            transactions.each do |transaction|

              # Create a RawIncreaseTransaction
              RawIncreaseTransaction.find_or_create_by(increase_transaction_id: transaction["id"]) do |rit|
                rit.amount_cents = transaction["amount"]
                rit.date_posted = transaction["created_at"]
                rit.increase_account_id = transaction["account_id"]
                rit.increase_route_type = transaction["route_type"]
                rit.increase_route_id = transaction["route_id"]
                rit.description = transaction["description"]
                rit.increase_transaction = transaction
              end

            end
          end

          true
        end

      end
    end
  end
end
