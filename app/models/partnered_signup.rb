# frozen_string_literal: true

class PartneredSignup < ApplicationRecord
  has_paper_trail

  include PublicIdentifiable
  set_public_id_prefix :sup

  belongs_to :partner, required: true
  belongs_to :event,   required: false
  belongs_to :user,    required: false

  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :unsubmitted, -> { where(submitted_at: nil) }
  scope :pending, -> { where(accepted_at: nil, rejected_at: nil).where.not(submitted_at: nil) }
  scope :not_pending, -> { where("accepted_at IS NOT NULL OR rejected_at IS NOT NULL") }
  scope :submitted, -> { where.not(submitted_at: nil) }

  validates :redirect_url, presence: true
  validate :not_accepted_and_rejected
  validates_presence_of [:organization_name,
                         :owner_name,
                         :owner_email,
                         :owner_phone,
                         :owner_address_line1,
                         # :owner_address_line2,
                         # ^ intentionally blank, as this is optional
                         :owner_address_city,
                         :owner_address_state,
                         :owner_address_postal_code,
                         :owner_address_country,
                         :owner_birthdate], unless: :unsubmitted?

  def continue_url
    Rails.application.routes.url_helpers.edit_partnered_signups_url(public_id: public_id)
  end

  def unsubmitted?
    !submitted?
  end

  def submitted?
    self.submitted_at.present?
  end

  def rejected?
    self.rejected_at.present?
  end

  def accepted?
    self.accepted_at.present?
  end

  def pending?
    !self.submitted_at.nil? and self.accepted_at.nil? and self.rejected_at.nil?
  end

  def status
    if rejected?
      "rejected"
    elsif accepted?
      "accepted"
    elsif submitted?
      "submitted"
    elsif unsubmitted?
      "unsubmitted"
    else
      Airbrake.notify("SUP #{self.id} in unknown status")
    end
  end

  private

  def not_accepted_and_rejected
    if accepted_at && rejected_at
      errors.add(:base, "Cannot be both accepted and rejected")
    end
  end

end
