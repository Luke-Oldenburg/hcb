# frozen_string_literal: true

require "rails_helper"

RSpec.describe CanonicalTransactionService::SetCustomMemo, type: :model do
  fixtures  "canonical_transactions"
  
  let(:canonical_transaction) { canonical_transactions(:canonical_transaction1) }
  let(:custom_memo) { "Custom Memo" }

  let(:attrs) do
    {
      canonical_transaction_id: canonical_transaction.id,
      custom_memo: custom_memo
    }
  end

  let(:service) { CanonicalTransactionService::SetCustomMemo.new(attrs) }

  it "sets custom memo" do
    service.run

    expect(canonical_transaction.reload.custom_memo).to eql(custom_memo)
  end

  context "custom memo is empty string" do
    let(:custom_memo) { " " }

    it "raises error if custom memo is blank" do
      expect do
        service.run
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "custom memo is nil" do
    let(:custom_memo) { nil }

    it "sets custom memo" do
      service.run

      expect(canonical_transaction.reload.custom_memo).to eql(nil)
    end
  end
end
