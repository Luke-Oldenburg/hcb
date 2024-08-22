# frozen_string_literal: true

# == Schema Information
#
# Table name: event_plans
#
#  id         :bigint           not null, primary key
#  aasm_state :string
#  plan_type  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
# Indexes
#
#  index_event_plans_on_event_id  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#
class Event
  class Plan
    class Standard < Plan
      def revenue_fee
        0.07
      end

      def label
        "Full Fiscal Sponsorship (#{revenue_fee_label})"
      end

      def description
        "Has access to all standard features, used for most organizations."
      end

      def features
        Event::Plan.available_features
      end

    end

  end

end
