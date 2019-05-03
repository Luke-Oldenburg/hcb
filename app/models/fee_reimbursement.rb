class FeeReimbursement < ApplicationRecord
  has_one :invoice
  has_one :t_transaction, class_name: 'Transaction', inverse_of: :fee_reimbursement
  has_many :comments, as: :commentable

  before_create :default_values

  scope :unprocessed, -> { includes(:t_transaction).where(processed_at: nil, transactions: { fee_reimbursement_id: nil }) }
  scope :pending, -> { where.not(processed_at: nil) }
  scope :completed, -> { includes(:t_transaction).where.not(transactions: { fee_reimbursement_id: nil }) }
  scope :failed, -> { where('processed_at < ?', Time.now - 5.days).pending }

  def unprocessed?
    processed_at.nil? && t_transaction.nil?
  end

  def pending?
    !processed_at.nil?
  end

  def completed?
    !t_transaction.nil?
  end

  def status
    return 'completed' if completed?
    return 'pending' if pending?

    'unprocessed'
  end

  def status_color
    return 'success' if completed?
    return 'info' if pending?

    'error'
  end

  def process
    processed_at = DateTime.now
  end

  private

  def default_values
    self.transaction_memo ||= "#{self.invoice.slug} FEE REIMBURSEMENT"
    self.fee_percentage ||= self.invoice.event.sponsorship_fee
    self.amount ||= self.invoice.item_amount - self.invoice.payout_creation_balance_net

    self.amount = 100 * fee_percent if self.amount < 100
  end

  def fee_percent
    if self.amount < 100
      self.fee_percentage = (self.amount * self.invoice.event.sponsorship_fee + (100 - self.amount)) / 100
    else
      self.invoice.event.sponsorship_fee
    end
  end
end
