# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id             :bigint           not null, primary key
#  aasm_state     :string
#  archived_at    :datetime
#  deleted_at     :datetime
#  name           :text
#  slug           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  archived_by_id :bigint
#  event_id       :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_documents_on_archived_by_id  (archived_by_id)
#  index_documents_on_event_id        (event_id)
#  index_documents_on_slug            (slug) UNIQUE
#  index_documents_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (archived_by_id => users.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (user_id => users.id)
#
class Document < ApplicationRecord
  include FriendlyId
  include AASM
  acts_as_paranoid

  friendly_id :slug_text, use: :slugged

  belongs_to :event, optional: true
  belongs_to :user
  belongs_to :archived_by, class_name: "User", optional: true

  has_one_attached :file
  has_many :downloads, class_name: "DocumentDownload", dependent: :destroy

  validates_presence_of :user, :name
  validate :ensure_file_attached

  scope :common, -> { where(event_id: nil) }

  aasm timestamps: true do
    state :active, initial: true
    state :archived, before_exit: -> do
      self.archived_by = nil
      self.archived_at = nil
    end

    event :mark_archive do
      transitions from: :active, to: :archived
      after do |archived_by = nil|
        update!(archived_by:) if archived_by.present?
      end

    end

    event :mark_unarchive do
      transitions from: :archived, to: :active
    end
  end

  def preview_url(resize: "500x500")
    return nil unless file&.attached?

    case file.content_type
    when "application/pdf"
      return nil unless file.previewable?

      file.preview(resize: resize)
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
         "application/msword"
      if Rails.env.staging?
        heroku_app_name = ENV["HEROKU_APP_NAME"]
        production_host = "https://#{heroku_app_name}.herokuapp.com"
      else
        production_host = Rails.application.routes.default_url_options[:host]
      end
      file_url = Rails.application.routes.url_helpers.rails_blob_url(file, host: production_host, only_path: false)
      preview = "https://drive.google.com/viewer?embedded=true&url=https%3A%2F%2Fcdn.discordapp.com%2Fattachments%2F1078317804148768849%2F1342744655326089217%2F6776b676dfd69_CAPTURE_THE_FLAG_RB.docx%3Fex%3D67babfe8%26is%3D67b96e68%26hm%3D78952181789677bdc9ec82053c394b3bcae4883e39d89be808f960926d518a68%26"
      Rails.logger.info "Preview URL: #{preview}"
      Rails.logger.info "File URL: #{file_url}"
      preview
    else
    end
  end

  def common?
    event_id.nil?
  end

  private

  # ActiveStorage doesn't yet support attachment validation (how dumb... see
  # https://github.com/rails/rails/issues/31656). This manually checks if a
  # file is attached for the time being.
  def ensure_file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def slug_text
    "#{self.event ? self.event.name : 'common'} #{self.name}"
  end

end
