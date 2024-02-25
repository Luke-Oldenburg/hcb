# frozen_string_literal: true

class ColumnService
  ENVIRONMENT = Rails.env.production? ? :production : :sandbox

  module Accounts
    FS_MAIN = Rails.application.credentials.column.dig(ENVIRONMENT, :fs_main_account_id)
    FS_OPERATING = Rails.application.credentials.column.dig(ENVIRONMENT, :fs_operating_account_id)

    def self.id_of(account_sym)
      const_get(account_sym.upcase)
    rescue
      raise ArgumentError, "unknown Column account: #{account_sym.inspect}"
    end
  end

  module AchCodes
    INSUFFICIENT_BALANCE = "R01"
    STOP_PAYMENT = "R08"
  end

  def self.conn
    @conn ||= Faraday.new url: "https://api.column.com" do |f|
      f.request :basic_auth, "", Rails.application.credentials.column.dig(ENVIRONMENT, :api_key)
      f.request :url_encoded
      f.response :raise_error
      f.response :json
    end
  end

  def self.get(url, params = {})
    conn.get(url, params).body
  end

  def self.post(url, params = {})
    idempotency_key = params.delete(:idempotency_key)
    conn.post(url, params, { "Idempotency-Key" => idempotency_key }.compact_blank).body
  end

  def self.transactions(from_date: 1.week.ago, to_date: Date.today, bank_account: Accounts::FS_MAIN)
    # 1: fetch daily reports from Column
    reports = get(
      "/reporting",
      type: "bank_account_transaction",
      limit: 100,
      from_date: from_date.to_date.iso8601,
      to_date: to_date.to_date.iso8601,
    )["reports"].select { |r| r["from_date"] == r["to_date"] && r["row_count"]&.>(0) }

    document_ids = reports.pluck "json_document_id"

    reports.to_h do |report|
      url = get("/documents/#{report["json_document_id"]}")["url"]
      transactions = JSON.parse(Faraday.get(url).body).select { |t| t["bank_account_id"] == bank_account && t["available_amount"] != 0 }

      [report["id"], transactions]
    end
  end

  def self.ach_transfer(id)
    get("/transfers/ach/#{id}")
  end

  def self.return_ach(id, with:)
    post("/transfers/ach/#{id}/return", return_code: with)
  end

end
