# frozen_string_literal: true

module InvoiceService
  class OpensToPaids
    def initialize(since_date: nil)
      @since_date = since_date || Time.now.utc - 6.months # only look back last 6 months
    end

    def run
      # 1. iterate over open invoices
      ::Invoice.open_v2.where("created_at >= ?", @since_date).pluck(:id).each do |invoice_id|
        ::InvoiceJob::OpenToPaid.perform_later(invoice_id)
      end
    end

  end
end
