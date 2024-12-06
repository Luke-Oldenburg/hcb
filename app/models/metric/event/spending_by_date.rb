# frozen_string_literal: true

# == Schema Information
#
# Table name: metrics
#
#  id           :bigint           not null, primary key
#  metric       :jsonb
#  subject_type :string
#  type         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  subject_id   :bigint
#
# Indexes
#
#  index_metrics_on_subject  (subject_type,subject_id)
#
class Metric
  module Event
    class SpendingByDate < Metric
      include Subject

      def calculate
        CanonicalTransaction
          .joins("LEFT JOIN canonical_event_mappings ON canonical_transactions.id = canonical_event_mappings.canonical_transaction_id")
          .where("canonical_event_mappings.event_id = ? AND EXTRACT(YEAR FROM canonical_transactions.created_at) = ?", event.id, 2024)
          .group("date(canonical_transactions.created_at)")
          .select(
            "date(canonical_transactions.created_at) AS transaction_date",
            "SUM(CASE WHEN amount_cents < 0 THEN amount_cents * -1 ELSE 0 END) AS amount_spent",
            "SUM(CASE WHEN amount_cents > 0 THEN amount_cents ELSE 0 END) AS amount_raised",
            "SUM(amount_cents) AS net_amount"
          )
          .order("transaction_date ASC")
          .each_with_object({}) { |item, hash| hash[item[:transaction_date]] = item[:net_amount] }
      end

    end
  end

end
