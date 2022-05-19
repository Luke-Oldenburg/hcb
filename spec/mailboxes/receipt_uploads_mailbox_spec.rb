# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReceiptUploadsMailbox, type: :mailbox do
  include ActionMailbox::TestHelper

  fixtures :events, :users, :canonical_transactions, :canonical_event_mappings

  let(:user) { users(:user1) }
  let(:event) { events(:event1) }
  let(:canonical_transaction) { canonical_transactions(:canonical_transaction_with_hcb) }
  let(:canonical_event_mapping) { canonical_event_mapping(:canonical_event_mapping2) }
  let(:receipt_filepath) { file_fixture("receipt.png") }
  let(:hcb) { canonical_transaction.local_hcb_code }
  before :each do
    event.users << user
  end


  it "routes email to mailbox" do
    expect(ReceiptUploadsMailbox)
      .to receive_inbound_email(to: "receipts+hcb-#{hcb.hashid}@example.com")
  end

  it "marks email as delivered" do
    mail = Mail.new do |m|
      m.from user.email
      m.to "receipts+hcb-#{hcb.hashid}@example.com"
      m.add_file File.join(Rails.root, receipt_filepath)
    end

    mail_processed = create_inbound_email_from_source(mail.to_s, status: :processing).tap(&:route)

    expect(mail_processed).to have_been_delivered
  end

  it "marks email as bounced if sent by non-user" do
    mail = Mail.new do |m|
      m.from "non-user@example.com"
      m.to "receipts+hcb-#{hcb.hashid}@example.com"
      m.add_file File.join(Rails.root, receipt_filepath)
    end

    mail_processed = create_inbound_email_from_source(mail.to_s, status: :processing).tap(&:route)

    expect(mail_processed).to have_bounced
  end

  it "marks email as bounced if no attachments" do
    mail = Mail.new do |m|
      m.from user.email
      m.to "receipts+hcb-#{hcb.hashid}@example.com"
    end
    mail_processed = process(mail)

    expect(mail_processed).to have_bounced
  end

  it "marks email as bounced if no valid hcb code found" do
    mail = Mail.new do |m|
      m.from user.email
      m.to "receipts+hcb-invalid@example.com"
      m.add_file File.join(Rails.root, receipt_filepath)
    end
    mail_processed = process(mail)

    expect(mail_processed).to have_bounced
  end
end
