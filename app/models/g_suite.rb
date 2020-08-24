class GSuite < ApplicationRecord
  VALID_DOMAIN = /[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix
  has_paper_trail

  include AASM

  has_one :application, class_name: 'GSuiteApplication', required: true
  has_many :accounts, class_name: 'GSuiteAccount'
  belongs_to :event
  has_many :comments, as: :commentable

  validates_presence_of :domain, :verification_key
  validates_uniqueness_of :domain
  validates_format_of :domain, with: VALID_DOMAIN

  after_initialize :set_application

  def verified_on_google?
    @verified_on_google ||= ::Partners::Google::GSuite::Domain.new(domain: domain).run.verified # TODO: move to a background job checking every 5-15 minutes for the latest verified domains
  rescue => e
    Airbrake.notify(e)

    false
  end

  def verified?
    self.accounts.any? { |account| !account.verified_at.null? }
  end

  def verification_url
    "https://www.google.com/webmasters/verification/verification?siteUrl=http://#{domain}"
  end

  def ou_name
    "##{event.id} #{event.name.to_s.gsub("+", "")}" # TODO: fix this brittleness. our ou's have been tied to Event.name but that has multiple issues - a user could change their event name, an event name might have non-permitted characters in it for an ou name. we should just use event.id. probably requires migration of all old ous
  end

  private

  def set_application
    self.application = GSuiteApplication.find_by(domain: domain)
  end
end
