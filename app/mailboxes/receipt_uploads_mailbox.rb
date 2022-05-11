# frozen_string_literal: true

class ReceiptUploadsMailbox < ApplicationMailbox
  # mail --> Mail object, this actual email
  # inbound_email => ActionMailbox::InboundEmail record  --> the active storage record
  before_processing :ensure_user
  before_processing :ensure_hcb
  before_processing :ensure_attachment
  before_processing :ensure_permissions

  def process
    result = ::ReceiptService::Create.new(
      receiptable: hcb,
      uploader: user,
      attachments: attachments
    ).run!

    if result&.any?
      bounce_with ReceiptUploadMailer.with(
        mail: inbound_email,
        reply_to: hcb.receipt_upload_email,
        receipts_count: result.size
      ).bounce_success
    else
      bounce_with ReceiptUploadMailer.with(
        mail: inbound_email,
        reply_to: hcb.receipt_upload_email
      ).bounce_error
    end
  end

  private

  def user
    @user ||= User.find_by email: mail.from
  end

  def hcb
    @email_comment ||= mail.to.first.match(/\+.*\@/i)[0]
    @hcb_code_hashid ||= @email_comment.match(/hcb-(.*)\@/i).captures.first
    @hcb ||= HcbCode.find_by_hashid @hcb_code_hashid
  end

  def attachments
    @attachments ||= mail.attachments.map do |atta|
      {
        io: StringIO.new(atta.decoded),
        content_type: atta.content_type,
        filename: atta.filename
      }
    end
  end

  def ensure_user?
    # Send email back if user is not found in the db make sure to send us an email from an account that does exist
    if user.nil?
      bounce_with ReceiptUploadMailer.with(mail: inbound_email).bounce_missing_user
    end
  end

  def ensure_hcb?
    # Send email back if hcb code can't be matched
    if hcb.nil?
      bounce_with ReceiptUploadMailer.with(mail: inbound_email).bounce_missing_hcb
    end
  end

  def ensure_attachment?
    # Send email back if we don't detect any attachments
    unless attachments.any?
      bounce_with ReceiptUploadMailer.with(mail: inbound_email, reply_to: hcb.receipt_upload_email).bounce_missing_attachment
    end

  end

  def ensure_permissions?
    # We return with the email equivalent of 404 if you don't have permission
    if hcb.event.users.include?(user)
      bounce_with ReceiptUploadMailer.with(mail: inbound_email).bounce_missing_hcb
    end
  end

end
