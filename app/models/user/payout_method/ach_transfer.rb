# frozen_string_literal: true

# == Schema Information
#
# Table name: user_payout_method_ach_transfers
#
#  id                        :bigint           not null, primary key
#  account_number_ciphertext :text             not null
#  routing_number_ciphertext :text             not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
class User
  module PayoutMethod
    class AchTransfer < ApplicationRecord
      self.table_name = "user_payout_method_ach_transfers"
      has_one :user, inverse_of: :payout_method, foreign_key: "payout_method_id"
      has_encrypted :account_number, :routing_number
      validates :routing_number, format: { with: /\A\d{9}\z/, message: "must be 9 digits" }
      validates :account_number, format: { with: /\A\d+\z/, message: "must be only numbers" }
      after_save_commit -> { Reimbursement::PayoutHolding.where(report: user.reimbursement_reports).failed.each(&:mark_settled!) }

      def kind
        "ach_transfer"
      end

      def icon
        "bank-account"
      end

      def name
        "an ACH transfer"
      end

    end
  end

end
