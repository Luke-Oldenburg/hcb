# frozen_string_literal: true

class DonationMailer < ApplicationMailer
  def donor_receipt
    @donation = params[:donation]
    @initial_recurring_donation = @donation.initial_recurring_donation? && !@donation.recurring_donation&.migrated_from_legacy_stripe_account?

    mail to: @donation.email, reply_to: @donation.event.donation_reply_to_email.presence, subject: @donation.recurring? ? "Receipt for your donation to #{@donation.event.name} — #{@donation.created_at.strftime("%B %Y")}" : "Receipt for your donation to #{@donation.event.name}"
  end

  def first_donation_notification
    @donation = params[:donation]
    @emails = @donation.event.users.map { |u| u.email }

    mail to: @emails, subject: "Congrats on receiving your first donation! 🎉"
  end

  def donation_with_message_notification
    @donation = params[:donation]
    @emails = @donation.event.users.pluck(:email)

    mail to: @emails, subject: "You've received a donation! 🎉"
  end

end
