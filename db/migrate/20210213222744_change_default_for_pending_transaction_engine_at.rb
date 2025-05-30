# frozen_string_literal: true

class ChangeDefaultForPendingTransactionEngineAt < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    change_column_default :events, :pending_transaction_engine_at, DateTime.new(2021, 2, 13, 22, 49, 40)
  end

end
