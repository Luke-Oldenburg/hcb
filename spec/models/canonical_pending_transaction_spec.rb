# frozen_string_literal: true

require "rails_helper"

RSpec.describe CanonicalPendingTransaction, type: :model do
  fixtures "canonical_pending_transactions", "raw_pending_stripe_transactions"

  let(:canonical_pending_transaction) { canonical_pending_transactions(:canonical_pending_transaction1) }

  it "is valid" do
    expect(canonical_pending_transaction).to be_valid
  end

  describe "hcb_code" do
    let(:attrs) do
      {
        amount_cents: 100,
        memo: "Pending Transaction",
        date: "2020-09-02"
      }
    end

    let(:canonical_pending_transaction) { CanonicalPendingTransaction.new(attrs) }
    let(:hcb_code) { canonical_pending_transaction.reload.hcb_code }

    before do
      canonical_pending_transaction.save!
    end

    it "calculates it on create" do
      expect(hcb_code).to eql("HCB-000-#{canonical_pending_transaction.id}")
    end

    context "when a stripe transaction" do
      let(:raw_pending_stripe_transaction) { raw_pending_stripe_transactions(:raw_pending_stripe_transaction1) }

      let(:attrs) do
        {
          amount_cents: 100,
          memo: "Pending Transaction",
          date: "2020-09-02",
          raw_pending_stripe_transaction_id: raw_pending_stripe_transaction.id
        }
      end

      it "calculates a different hcb code" do
        expect(hcb_code).to eql("HCB-600-#{raw_pending_stripe_transaction.stripe_transaction_id}")
      end
    end
  end
end
