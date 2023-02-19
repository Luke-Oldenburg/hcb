# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_02_17_181936) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "ach_payments", force: :cascade do |t|
    t.text "stripe_source_transaction_id"
    t.text "stripe_charge_id"
    t.bigint "stripe_ach_payment_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fee_reimbursement_id"
    t.text "stripe_payout_id"
    t.index ["fee_reimbursement_id"], name: "index_ach_payments_on_fee_reimbursement_id"
    t.index ["stripe_ach_payment_source_id"], name: "index_ach_payments_on_stripe_ach_payment_source_id"
  end

  create_table "ach_transfers", force: :cascade do |t|
    t.bigint "event_id"
    t.bigint "creator_id"
    t.string "routing_number"
    t.string "bank_name"
    t.string "recipient_name"
    t.integer "amount"
    t.datetime "approved_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "recipient_tel"
    t.datetime "rejected_at", precision: nil
    t.datetime "scheduled_arrival_date", precision: nil
    t.text "payment_for"
    t.string "aasm_state"
    t.text "confirmation_number"
    t.text "account_number_ciphertext"
    t.bigint "processor_id"
    t.index ["creator_id"], name: "index_ach_transfers_on_creator_id"
    t.index ["event_id"], name: "index_ach_transfers_on_event_id"
    t.index ["processor_id"], name: "index_ach_transfers_on_processor_id"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time", precision: nil
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at", precision: nil
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.text "plaid_item_id"
    t.text "plaid_account_id"
    t.text "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "should_sync", default: true
    t.boolean "is_positive_pay"
    t.boolean "should_sync_v2", default: false
    t.datetime "failed_at", precision: nil
    t.integer "failure_count", default: 0
    t.text "plaid_access_token_ciphertext"
  end

  create_table "bank_fees", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "hcb_code"
    t.string "aasm_state"
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fee_revenue_id"
    t.index ["event_id"], name: "index_bank_fees_on_event_id"
    t.index ["fee_revenue_id"], name: "index_bank_fees_on_fee_revenue_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", precision: nil
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "canonical_event_mappings", force: :cascade do |t|
    t.bigint "canonical_transaction_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["canonical_transaction_id"], name: "index_canonical_event_mappings_on_canonical_transaction_id"
    t.index ["event_id", "canonical_transaction_id"], name: "index_cem_event_id_canonical_transaction_id_uniqueness", unique: true
    t.index ["event_id"], name: "index_canonical_event_mappings_on_event_id"
    t.index ["user_id"], name: "index_canonical_event_mappings_on_user_id"
  end

  create_table "canonical_hashed_mappings", force: :cascade do |t|
    t.bigint "canonical_transaction_id", null: false
    t.bigint "hashed_transaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_transaction_id"], name: "index_canonical_hashed_mappings_on_canonical_transaction_id"
    t.index ["hashed_transaction_id"], name: "index_canonical_hashed_mappings_on_hashed_transaction_id"
  end

  create_table "canonical_pending_declined_mappings", force: :cascade do |t|
    t.bigint "canonical_pending_transaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_pending_transaction_id"], name: "index_canonical_pending_declined_mappings_on_cpt_id", unique: true
  end

  create_table "canonical_pending_event_mappings", force: :cascade do |t|
    t.bigint "canonical_pending_transaction_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_pending_transaction_id"], name: "index_canonical_pending_event_map_on_canonical_pending_tx_id"
    t.index ["event_id"], name: "index_canonical_pending_event_mappings_on_event_id"
  end

  create_table "canonical_pending_settled_mappings", force: :cascade do |t|
    t.bigint "canonical_pending_transaction_id", null: false
    t.bigint "canonical_transaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_pending_transaction_id"], name: "index_canonical_pending_settled_map_on_canonical_pending_tx_id"
    t.index ["canonical_transaction_id"], name: "index_canonical_pending_settled_mappings_on_canonical_tx_id"
  end

  create_table "canonical_pending_transactions", force: :cascade do |t|
    t.date "date", null: false
    t.text "memo", null: false
    t.integer "amount_cents", null: false
    t.bigint "raw_pending_stripe_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "raw_pending_outgoing_check_transaction_id"
    t.bigint "raw_pending_outgoing_ach_transaction_id"
    t.bigint "raw_pending_donation_transaction_id"
    t.bigint "raw_pending_invoice_transaction_id"
    t.text "hcb_code"
    t.bigint "raw_pending_bank_fee_transaction_id"
    t.bigint "raw_pending_partner_donation_transaction_id"
    t.text "custom_memo"
    t.bigint "raw_pending_incoming_disbursement_transaction_id"
    t.bigint "raw_pending_outgoing_disbursement_transaction_id"
    t.boolean "fronted", default: false
    t.boolean "fee_waived", default: false
    t.bigint "ach_payment_id"
    t.index ["ach_payment_id"], name: "index_canonical_pending_transactions_on_ach_payment_id"
    t.index ["hcb_code"], name: "index_canonical_pending_transactions_on_hcb_code"
    t.index ["raw_pending_bank_fee_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_bank_fee_tx_id"
    t.index ["raw_pending_donation_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_donation_tx_id"
    t.index ["raw_pending_incoming_disbursement_transaction_id"], name: "index_cpts_on_raw_pending_incoming_disbursement_transaction_id"
    t.index ["raw_pending_invoice_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_invoice_tx_id"
    t.index ["raw_pending_outgoing_ach_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_outgoing_ach_tx_id"
    t.index ["raw_pending_outgoing_check_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_outgoing_check_tx_id"
    t.index ["raw_pending_outgoing_disbursement_transaction_id"], name: "index_cpts_on_raw_pending_outgoing_disbursement_transaction_id"
    t.index ["raw_pending_partner_donation_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_partner_dntn_tx_id"
    t.index ["raw_pending_stripe_transaction_id"], name: "index_canonical_pending_txs_on_raw_pending_stripe_tx_id"
    t.check_constraint "fronted IS NOT NULL", name: "canonical_pending_transactions_fronted_null"
  end

  create_table "canonical_transactions", force: :cascade do |t|
    t.date "date", null: false
    t.text "memo", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "friendly_memo"
    t.text "custom_memo"
    t.text "hcb_code"
    t.index ["date"], name: "index_canonical_transactions_on_date"
    t.index ["hcb_code"], name: "index_canonical_transactions_on_hcb_code"
  end

  create_table "checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "lob_address_id"
    t.string "lob_id"
    t.text "memo"
    t.integer "check_number"
    t.integer "amount"
    t.datetime "expected_delivery_date", precision: nil
    t.datetime "send_date", precision: nil
    t.string "transaction_memo"
    t.datetime "voided_at", precision: nil
    t.datetime "approved_at", precision: nil
    t.datetime "exported_at", precision: nil
    t.datetime "refunded_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "rejected_at", precision: nil
    t.text "payment_for"
    t.string "aasm_state"
    t.text "lob_url"
    t.text "description_ciphertext"
    t.index ["creator_id"], name: "index_checks_on_creator_id"
    t.index ["lob_address_id"], name: "index_checks_on_lob_address_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type"
    t.bigint "commentable_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "admin_only", default: false, null: false
    t.boolean "has_untracked_edit", default: false, null: false
    t.text "content_ciphertext"
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "disbursements", force: :cascade do |t|
    t.bigint "event_id"
    t.integer "amount"
    t.string "name"
    t.datetime "rejected_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "source_event_id"
    t.datetime "errored_at", precision: nil
    t.bigint "requested_by_id"
    t.bigint "fulfilled_by_id"
    t.string "aasm_state"
    t.datetime "pending_at", precision: nil
    t.datetime "in_transit_at", precision: nil
    t.datetime "deposited_at", precision: nil
    t.index ["event_id"], name: "index_disbursements_on_event_id"
    t.index ["fulfilled_by_id"], name: "index_disbursements_on_fulfilled_by_id"
    t.index ["requested_by_id"], name: "index_disbursements_on_requested_by_id"
    t.index ["source_event_id"], name: "index_disbursements_on_source_event_id"
  end

  create_table "document_downloads", force: :cascade do |t|
    t.bigint "document_id"
    t.bigint "user_id"
    t.inet "ip_address"
    t.text "user_agent"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["document_id"], name: "index_document_downloads_on_document_id"
    t.index ["user_id"], name: "index_document_downloads_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "event_id"
    t.text "name"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "slug"
    t.index ["event_id"], name: "index_documents_on_event_id"
    t.index ["slug"], name: "index_documents_on_slug", unique: true
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "donation_payouts", force: :cascade do |t|
    t.text "stripe_payout_id"
    t.bigint "amount"
    t.datetime "arrival_date", precision: nil
    t.boolean "automatic"
    t.text "stripe_balance_transaction_id"
    t.datetime "stripe_created_at", precision: nil
    t.text "currency"
    t.text "description"
    t.text "stripe_destination_id"
    t.text "failure_stripe_balance_transaction_id"
    t.text "failure_code"
    t.text "failure_message"
    t.text "method"
    t.text "source_type"
    t.text "statement_descriptor"
    t.text "status"
    t.text "type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["failure_stripe_balance_transaction_id"], name: "index_donation_payouts_on_failure_stripe_balance_transaction_id", unique: true
    t.index ["stripe_balance_transaction_id"], name: "index_donation_payouts_on_stripe_balance_transaction_id", unique: true
    t.index ["stripe_payout_id"], name: "index_donation_payouts_on_stripe_payout_id", unique: true
  end

  create_table "donations", force: :cascade do |t|
    t.text "email"
    t.text "name"
    t.string "url_hash"
    t.integer "amount"
    t.integer "amount_received"
    t.string "status"
    t.string "stripe_client_secret"
    t.string "stripe_payment_intent_id"
    t.datetime "payout_creation_queued_at", precision: nil
    t.datetime "payout_creation_queued_for", precision: nil
    t.string "payout_creation_queued_job_id"
    t.integer "payout_creation_balance_net"
    t.integer "payout_creation_balance_stripe_fee"
    t.datetime "payout_creation_balance_available_at", precision: nil
    t.bigint "event_id"
    t.bigint "payout_id"
    t.bigint "fee_reimbursement_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "message"
    t.text "hcb_code"
    t.string "aasm_state"
    t.bigint "recurring_donation_id"
    t.index ["event_id"], name: "index_donations_on_event_id"
    t.index ["fee_reimbursement_id"], name: "index_donations_on_fee_reimbursement_id"
    t.index ["payout_id"], name: "index_donations_on_payout_id"
    t.index ["recurring_donation_id"], name: "index_donations_on_recurring_donation_id"
  end

  create_table "emburse_card_requests", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "event_id"
    t.bigint "fulfilled_by_id"
    t.datetime "fulfilled_at", precision: nil
    t.bigint "daily_limit"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "shipping_address"
    t.string "full_name"
    t.datetime "rejected_at", precision: nil
    t.datetime "accepted_at", precision: nil
    t.datetime "canceled_at", precision: nil
    t.text "notes"
    t.bigint "emburse_card_id"
    t.string "shipping_address_street_one"
    t.string "shipping_address_street_two"
    t.string "shipping_address_city"
    t.string "shipping_address_state"
    t.string "shipping_address_zip"
    t.boolean "is_virtual"
    t.index ["creator_id"], name: "index_emburse_card_requests_on_creator_id"
    t.index ["emburse_card_id"], name: "index_emburse_card_requests_on_emburse_card_id"
    t.index ["event_id"], name: "index_emburse_card_requests_on_event_id"
    t.index ["fulfilled_by_id"], name: "index_emburse_card_requests_on_fulfilled_by_id"
  end

  create_table "emburse_cards", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "event_id"
    t.bigint "daily_limit"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "last_four"
    t.string "full_name"
    t.text "address"
    t.integer "expiration_month"
    t.integer "expiration_year"
    t.text "emburse_id"
    t.text "slug"
    t.datetime "deactivated_at", precision: nil
    t.boolean "is_virtual"
    t.string "emburse_state"
    t.index ["event_id"], name: "index_emburse_cards_on_event_id"
    t.index ["slug"], name: "index_emburse_cards_on_slug", unique: true
    t.index ["user_id"], name: "index_emburse_cards_on_user_id"
  end

  create_table "emburse_transactions", force: :cascade do |t|
    t.string "emburse_id"
    t.integer "amount"
    t.integer "state"
    t.string "emburse_department_id"
    t.bigint "event_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "notified_admin_at", precision: nil
    t.string "emburse_card_uuid"
    t.bigint "emburse_card_id"
    t.bigint "merchant_mid"
    t.integer "merchant_mcc"
    t.text "merchant_name"
    t.text "merchant_address"
    t.text "merchant_city"
    t.text "merchant_state"
    t.text "merchant_zip"
    t.text "category_emburse_id"
    t.text "category_url"
    t.text "category_code"
    t.text "category_name"
    t.text "category_parent"
    t.text "label"
    t.text "location"
    t.text "note"
    t.text "receipt_url"
    t.text "receipt_filename"
    t.datetime "transaction_time", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "marked_no_or_lost_receipt_at", precision: nil
    t.index ["deleted_at"], name: "index_emburse_transactions_on_deleted_at"
    t.index ["emburse_card_id"], name: "index_emburse_transactions_on_emburse_card_id"
    t.index ["event_id"], name: "index_emburse_transactions_on_event_id"
  end

  create_table "emburse_transfers", force: :cascade do |t|
    t.bigint "emburse_card_id"
    t.bigint "creator_id"
    t.bigint "fulfilled_by_id"
    t.bigint "load_amount"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "accepted_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.datetime "canceled_at", precision: nil
    t.string "emburse_transaction_id"
    t.bigint "event_id"
    t.index ["creator_id"], name: "index_emburse_transfers_on_creator_id"
    t.index ["emburse_card_id"], name: "index_emburse_transfers_on_emburse_card_id"
    t.index ["event_id"], name: "index_emburse_transfers_on_event_id"
    t.index ["fulfilled_by_id"], name: "index_emburse_transfers_on_fulfilled_by_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "name"
    t.datetime "start", precision: nil
    t.datetime "end", precision: nil
    t.text "address"
    t.decimal "sponsorship_fee"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "emburse_department_id"
    t.text "slug"
    t.bigint "point_of_contact_id"
    t.integer "expected_budget"
    t.boolean "has_fiscal_sponsorship_document"
    t.text "club_airtable_id"
    t.boolean "beta_features_enabled"
    t.datetime "hidden_at", precision: nil
    t.boolean "donation_page_enabled", default: true
    t.text "donation_page_message"
    t.boolean "is_public", default: true
    t.text "public_message"
    t.boolean "omit_stats", default: false
    t.datetime "transaction_engine_v2_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "last_fee_processed_at", precision: nil
    t.datetime "pending_transaction_engine_at", precision: nil, default: "2021-02-13 22:49:40"
    t.string "aasm_state"
    t.string "organization_identifier", null: false
    t.string "redirect_url"
    t.bigint "partner_id", null: false
    t.string "owner_name"
    t.string "owner_email"
    t.string "owner_phone"
    t.string "owner_address"
    t.date "owner_birthdate"
    t.string "webhook_url"
    t.integer "country"
    t.boolean "holiday_features", default: true, null: false
    t.boolean "organized_by_hack_clubbers"
    t.string "custom_css_url"
    t.integer "category"
    t.boolean "can_front_balance", default: true, null: false
    t.boolean "demo_mode", default: false, null: false
    t.datetime "demo_mode_request_meeting_at", precision: nil
    t.boolean "is_indexable", default: true
    t.datetime "deleted_at", precision: nil
    t.index ["club_airtable_id"], name: "index_events_on_club_airtable_id", unique: true
    t.index ["partner_id", "organization_identifier"], name: "index_events_on_partner_id_and_organization_identifier", unique: true
    t.index ["partner_id"], name: "index_events_on_partner_id"
    t.index ["point_of_contact_id"], name: "index_events_on_point_of_contact_id"
  end

  create_table "exports", force: :cascade do |t|
    t.text "type"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["type"], name: "index_exports_on_type"
    t.index ["user_id"], name: "index_exports_on_user_id"
  end

  create_table "fee_reimbursements", force: :cascade do |t|
    t.bigint "amount"
    t.string "transaction_memo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "processed_at", precision: nil
    t.index ["transaction_memo"], name: "index_fee_reimbursements_on_transaction_memo", unique: true
  end

  create_table "fee_relationships", force: :cascade do |t|
    t.bigint "event_id"
    t.boolean "fee_applies"
    t.bigint "fee_amount"
    t.boolean "is_fee_payment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_fee_relationships_on_event_id"
  end

  create_table "fee_revenues", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "start"
    t.date "end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "aasm_state"
  end

  create_table "fees", force: :cascade do |t|
    t.bigint "canonical_event_mapping_id", null: false
    t.decimal "amount_cents_as_decimal"
    t.decimal "event_sponsorship_fee"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_event_mapping_id"], name: "index_fees_on_canonical_event_mapping_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "g_suite_accounts", force: :cascade do |t|
    t.text "address"
    t.datetime "accepted_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.bigint "g_suite_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "verified_at", precision: nil
    t.bigint "creator_id"
    t.text "backup_email"
    t.string "first_name"
    t.string "last_name"
    t.datetime "suspended_at", precision: nil
    t.text "initial_password_ciphertext"
    t.index ["creator_id"], name: "index_g_suite_accounts_on_creator_id"
    t.index ["g_suite_id"], name: "index_g_suite_accounts_on_g_suite_id"
  end

  create_table "g_suites", force: :cascade do |t|
    t.citext "domain"
    t.bigint "event_id"
    t.text "verification_key"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "dkim_key"
    t.string "aasm_state", default: "creating"
    t.bigint "created_by_id"
    t.text "remote_org_unit_id"
    t.text "remote_org_unit_path"
    t.index ["created_by_id"], name: "index_g_suites_on_created_by_id"
    t.index ["event_id"], name: "index_g_suites_on_event_id"
  end

  create_table "hashed_transactions", force: :cascade do |t|
    t.text "primary_hash"
    t.text "secondary_hash"
    t.bigint "raw_plaid_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "raw_emburse_transaction_id"
    t.text "primary_hash_input"
    t.bigint "duplicate_of_hashed_transaction_id"
    t.bigint "raw_csv_transaction_id"
    t.bigint "raw_stripe_transaction_id"
    t.text "unique_bank_identifier"
    t.date "date"
    t.index ["duplicate_of_hashed_transaction_id"], name: "index_hashed_transactions_on_duplicate_of_hashed_transaction_id"
    t.index ["raw_csv_transaction_id"], name: "index_hashed_transactions_on_raw_csv_transaction_id"
    t.index ["raw_plaid_transaction_id"], name: "index_hashed_transactions_on_raw_plaid_transaction_id"
    t.index ["raw_stripe_transaction_id"], name: "index_hashed_transactions_on_raw_stripe_transaction_id"
  end

  create_table "hcb_codes", force: :cascade do |t|
    t.text "hcb_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "marked_no_or_lost_receipt_at", precision: nil
    t.text "short_code"
    t.index ["hcb_code"], name: "index_hcb_codes_on_hcb_code", unique: true
    t.check_constraint "short_code = upper(short_code)", name: "constraint_hcb_codes_on_short_code_to_uppercase"
  end

  create_table "hcb_codes_tags", id: false, force: :cascade do |t|
    t.bigint "hcb_code_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["hcb_code_id", "tag_id"], name: "index_hcb_codes_tags_on_hcb_code_id_and_tag_id", unique: true
  end

  create_table "invoice_payouts", force: :cascade do |t|
    t.text "stripe_payout_id"
    t.bigint "amount"
    t.datetime "arrival_date", precision: nil
    t.boolean "automatic"
    t.text "stripe_balance_transaction_id"
    t.datetime "stripe_created_at", precision: nil
    t.text "currency"
    t.text "description"
    t.text "stripe_destination_id"
    t.text "failure_stripe_balance_transaction_id"
    t.text "failure_code"
    t.text "failure_message"
    t.text "method"
    t.text "source_type"
    t.text "statement_descriptor"
    t.text "status"
    t.text "type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["failure_stripe_balance_transaction_id"], name: "index_invoice_payouts_on_failure_stripe_balance_transaction_id", unique: true
    t.index ["stripe_balance_transaction_id"], name: "index_invoice_payouts_on_stripe_balance_transaction_id", unique: true
    t.index ["stripe_payout_id"], name: "index_invoice_payouts_on_stripe_payout_id", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "sponsor_id"
    t.text "stripe_invoice_id"
    t.bigint "amount_due"
    t.bigint "amount_paid"
    t.bigint "amount_remaining"
    t.bigint "attempt_count"
    t.boolean "attempted"
    t.text "stripe_charge_id"
    t.text "memo"
    t.datetime "due_date", precision: nil
    t.bigint "ending_balance"
    t.bigint "starting_balance"
    t.text "statement_descriptor"
    t.bigint "subtotal"
    t.bigint "tax"
    t.decimal "tax_percent"
    t.bigint "total"
    t.text "item_description"
    t.bigint "item_amount"
    t.text "item_stripe_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "auto_advance"
    t.text "hosted_invoice_url"
    t.text "invoice_pdf"
    t.bigint "creator_id"
    t.datetime "manually_marked_as_paid_at", precision: nil
    t.bigint "manually_marked_as_paid_user_id"
    t.text "manually_marked_as_paid_reason"
    t.bigint "payout_id"
    t.datetime "payout_creation_queued_at", precision: nil
    t.datetime "payout_creation_queued_for", precision: nil
    t.text "payout_creation_queued_job_id"
    t.datetime "payout_creation_balance_available_at", precision: nil
    t.text "slug"
    t.text "number"
    t.datetime "finalized_at", precision: nil
    t.text "status"
    t.integer "payout_creation_balance_net"
    t.integer "payout_creation_balance_stripe_fee"
    t.boolean "reimbursable", default: true
    t.bigint "fee_reimbursement_id"
    t.boolean "livemode"
    t.text "payment_method_type"
    t.text "payment_method_card_brand"
    t.text "payment_method_card_checks_address_line1_check"
    t.text "payment_method_card_checks_address_postal_code_check"
    t.text "payment_method_card_checks_cvc_check"
    t.text "payment_method_card_country"
    t.text "payment_method_card_exp_month"
    t.text "payment_method_card_exp_year"
    t.text "payment_method_card_funding"
    t.text "payment_method_card_last4"
    t.text "payment_method_ach_credit_transfer_bank_name"
    t.text "payment_method_ach_credit_transfer_routing_number"
    t.text "payment_method_ach_credit_transfer_swift_code"
    t.datetime "archived_at", precision: nil
    t.bigint "archived_by_id"
    t.text "hcb_code"
    t.string "aasm_state"
    t.text "payment_method_ach_credit_transfer_account_number_ciphertext"
    t.index ["archived_by_id"], name: "index_invoices_on_archived_by_id"
    t.index ["creator_id"], name: "index_invoices_on_creator_id"
    t.index ["fee_reimbursement_id"], name: "index_invoices_on_fee_reimbursement_id"
    t.index ["item_stripe_id"], name: "index_invoices_on_item_stripe_id", unique: true
    t.index ["manually_marked_as_paid_user_id"], name: "index_invoices_on_manually_marked_as_paid_user_id"
    t.index ["payout_creation_queued_job_id"], name: "index_invoices_on_payout_creation_queued_job_id", unique: true
    t.index ["payout_id"], name: "index_invoices_on_payout_id"
    t.index ["slug"], name: "index_invoices_on_slug", unique: true
    t.index ["sponsor_id"], name: "index_invoices_on_sponsor_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["stripe_invoice_id"], name: "index_invoices_on_stripe_invoice_id", unique: true
  end

  create_table "lab_tech_experiments", force: :cascade do |t|
    t.string "name"
    t.integer "percent_enabled", default: 0, null: false
    t.integer "equivalent_count", default: 0, null: false
    t.integer "timed_out_count", default: 0, null: false
    t.integer "other_error_count", default: 0, null: false
    t.index ["name"], name: "index_lab_tech_experiments_by_name", unique: true
  end

  create_table "lab_tech_observations", force: :cascade do |t|
    t.integer "result_id", null: false
    t.string "name", limit: 100
    t.float "duration"
    t.text "value"
    t.text "sql"
    t.string "exception_class"
    t.text "exception_message"
    t.text "exception_backtrace"
    t.datetime "created_at", precision: nil
    t.text "diff"
    t.index ["result_id"], name: "index_lab_tech_observations_by_result_id"
  end

  create_table "lab_tech_results", force: :cascade do |t|
    t.integer "experiment_id", null: false
    t.text "context"
    t.boolean "equivalent", default: false, null: false
    t.boolean "raised_error", default: false, null: false
    t.float "time_delta"
    t.float "speedup_factor"
    t.datetime "created_at", precision: nil
    t.boolean "timed_out", default: false, null: false
    t.float "control_duration"
    t.float "candidate_duration"
    t.index ["experiment_id", "equivalent"], name: "index_lab_tech_results_by_exp_id_and_equivalent"
    t.index ["experiment_id", "raised_error"], name: "index_lab_tech_results_by_exp_id_and_raised"
  end

  create_table "lob_addresses", force: :cascade do |t|
    t.bigint "event_id"
    t.text "description"
    t.string "name"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "lob_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_lob_addresses_on_event_id"
  end

  create_table "login_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "token", null: false
    t.datetime "expiration_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ip"
    t.string "aasm_state"
    t.bigint "user_session_id"
    t.bigint "partner_id"
    t.decimal "latitude"
    t.decimal "longitude"
    t.index ["partner_id"], name: "index_login_tokens_on_partner_id"
    t.index ["token"], name: "index_login_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_login_tokens_on_user_id"
    t.index ["user_session_id"], name: "index_login_tokens_on_user_session_id"
  end

  create_table "mfa_codes", force: :cascade do |t|
    t.text "message"
    t.string "code"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mfa_requests", force: :cascade do |t|
    t.string "provider"
    t.bigint "mfa_code_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mfa_code_id"], name: "index_mfa_requests_on_mfa_code_id"
  end

  create_table "ops_checkins", force: :cascade do |t|
    t.bigint "point_of_contact_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["point_of_contact_id"], name: "index_ops_checkins_on_point_of_contact_id"
  end

  create_table "organizer_position_deletion_requests", force: :cascade do |t|
    t.bigint "organizer_position_id"
    t.bigint "submitted_by_id"
    t.bigint "closed_by_id"
    t.datetime "closed_at", precision: nil
    t.text "reason"
    t.boolean "subject_has_outstanding_expenses_expensify", default: false, null: false
    t.boolean "subject_has_outstanding_transactions_emburse", default: false, null: false
    t.boolean "subject_emails_should_be_forwarded", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "subject_has_outstanding_transactions_stripe", default: false, null: false
    t.boolean "subject_has_active_cards", default: false, null: false
    t.index ["closed_by_id"], name: "index_organizer_position_deletion_requests_on_closed_by_id"
    t.index ["organizer_position_id"], name: "index_organizer_deletion_requests_on_organizer_position_id"
    t.index ["submitted_by_id"], name: "index_organizer_position_deletion_requests_on_submitted_by_id"
  end

  create_table "organizer_position_invites", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "user_id", null: false
    t.bigint "sender_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "accepted_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.bigint "organizer_position_id"
    t.datetime "cancelled_at", precision: nil
    t.string "slug"
    t.boolean "initial", default: false
    t.boolean "is_signee"
    t.index ["event_id"], name: "index_organizer_position_invites_on_event_id"
    t.index ["organizer_position_id"], name: "index_organizer_position_invites_on_organizer_position_id"
    t.index ["sender_id"], name: "index_organizer_position_invites_on_sender_id"
    t.index ["slug"], name: "index_organizer_position_invites_on_slug", unique: true
    t.index ["user_id"], name: "index_organizer_position_invites_on_user_id"
  end

  create_table "organizer_positions", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "event_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "sort_index"
    t.boolean "first_time", default: true
    t.boolean "is_signee"
    t.index ["event_id"], name: "index_organizer_positions_on_event_id"
    t.index ["user_id"], name: "index_organizer_positions_on_user_id"
  end

  create_table "outgoing_twilio_messages", force: :cascade do |t|
    t.bigint "twilio_message_id"
    t.bigint "hcb_code_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hcb_code_id"], name: "index_outgoing_twilio_messages_on_hcb_code_id"
    t.index ["twilio_message_id"], name: "index_outgoing_twilio_messages_on_twilio_message_id"
  end

  create_table "partner_donations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "hcb_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "aasm_state"
    t.integer "payout_amount_cents"
    t.string "stripe_charge_id"
    t.datetime "stripe_charge_created_at", precision: nil
    t.index ["event_id"], name: "index_partner_donations_on_event_id"
  end

  create_table "partnered_signups", force: :cascade do |t|
    t.string "owner_phone"
    t.string "owner_email"
    t.string "owner_name"
    t.string "owner_address"
    t.string "redirect_url", null: false
    t.date "owner_birthdate"
    t.integer "country"
    t.string "organization_name", null: false
    t.datetime "accepted_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.bigint "user_id"
    t.bigint "event_id"
    t.bigint "partner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "submitted_at", precision: nil
    t.string "docusign_envelope_id"
    t.boolean "signed_contract"
    t.string "owner_address_line1"
    t.string "owner_address_line2"
    t.string "owner_address_city"
    t.string "owner_address_state"
    t.text "owner_address_postal_code"
    t.integer "owner_address_country"
    t.string "aasm_state"
    t.datetime "applicant_signed_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.boolean "legal_acknowledgement"
    t.index ["event_id"], name: "index_partnered_signups_on_event_id"
    t.index ["partner_id"], name: "index_partnered_signups_on_partner_id"
    t.index ["user_id"], name: "index_partnered_signups_on_user_id"
  end

  create_table "partners", force: :cascade do |t|
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "external", default: true, null: false
    t.text "name"
    t.text "logo"
    t.string "public_stripe_api_key"
    t.text "stripe_api_key_ciphertext"
    t.string "webhook_url"
    t.string "docusign_template_id"
    t.bigint "representative_id"
    t.text "api_key_ciphertext"
    t.string "api_key_bidx"
    t.index ["api_key_bidx"], name: "index_partners_on_api_key_bidx", unique: true
    t.index ["representative_id"], name: "index_partners_on_representative_id"
  end

  create_table "raw_csv_transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "date_posted"
    t.text "memo"
    t.jsonb "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_bank_identifier", null: false
    t.text "csv_transaction_id"
    t.index ["csv_transaction_id"], name: "index_raw_csv_transactions_on_csv_transaction_id", unique: true
  end

  create_table "raw_emburse_transactions", force: :cascade do |t|
    t.text "emburse_transaction_id"
    t.jsonb "emburse_transaction"
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_bank_identifier", null: false
  end

  create_table "raw_pending_bank_fee_transactions", force: :cascade do |t|
    t.string "bank_fee_transaction_id"
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "raw_pending_donation_transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.string "donation_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "raw_pending_incoming_disbursement_transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.bigint "disbursement_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disbursement_id"], name: "index_rpidts_on_disbursement_id"
  end

  create_table "raw_pending_invoice_transactions", force: :cascade do |t|
    t.string "invoice_transaction_id"
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "raw_pending_outgoing_ach_transactions", force: :cascade do |t|
    t.text "ach_transaction_id"
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "raw_pending_outgoing_check_transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "check_transaction_id"
  end

  create_table "raw_pending_outgoing_disbursement_transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.bigint "disbursement_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disbursement_id"], name: "index_rpodts_on_disbursement_id"
  end

  create_table "raw_pending_partner_donation_transactions", force: :cascade do |t|
    t.text "partner_donation_transaction_id"
    t.integer "amount_cents"
    t.date "date_posted"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "raw_pending_stripe_transactions", force: :cascade do |t|
    t.text "stripe_transaction_id"
    t.jsonb "stripe_transaction"
    t.integer "amount_cents"
    t.date "date_posted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "(((stripe_transaction -> 'card'::text) ->> 'id'::text))", name: "index_raw_pending_stripe_transactions_on_card_id_text", using: :hash
    t.index "((stripe_transaction ->> 'status'::text))", name: "index_raw_pending_stripe_transactions_on_status_text", using: :hash
  end

  create_table "raw_plaid_transactions", force: :cascade do |t|
    t.text "plaid_account_id"
    t.text "plaid_item_id"
    t.text "plaid_transaction_id"
    t.jsonb "plaid_transaction"
    t.integer "amount_cents"
    t.date "date_posted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pending", default: false
    t.string "unique_bank_identifier", null: false
  end

  create_table "raw_stripe_transactions", force: :cascade do |t|
    t.text "stripe_transaction_id"
    t.jsonb "stripe_transaction"
    t.integer "amount_cents"
    t.date "date_posted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "stripe_authorization_id"
    t.string "unique_bank_identifier", null: false
    t.index "(((stripe_transaction -> 'card'::text) ->> 'id'::text))", name: "index_raw_stripe_transactions_on_card_id_text", using: :hash
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "attempted_match_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "receiptable_type"
    t.bigint "receiptable_id"
    t.integer "upload_method"
    t.index ["receiptable_type", "receiptable_id"], name: "index_receipts_on_receiptable_type_and_receiptable_id"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "recurring_donations", force: :cascade do |t|
    t.text "email"
    t.text "name"
    t.bigint "event_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "stripe_customer_id"
    t.text "stripe_subscription_id"
    t.text "stripe_payment_intent_id"
    t.text "stripe_client_secret"
    t.datetime "stripe_current_period_end"
    t.text "stripe_status"
    t.text "url_hash"
    t.text "last4_ciphertext"
    t.datetime "canceled_at"
    t.boolean "migrated_from_legacy_stripe_account"
    t.index ["event_id"], name: "index_recurring_donations_on_event_id"
    t.index ["stripe_subscription_id"], name: "index_recurring_donations_on_stripe_subscription_id", unique: true
    t.index ["url_hash"], name: "index_recurring_donations_on_url_hash", unique: true
  end

  create_table "selenium_sessions", force: :cascade do |t|
    t.string "aasm_state"
    t.jsonb "cookies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sponsors", force: :cascade do |t|
    t.bigint "event_id"
    t.text "name"
    t.text "contact_email"
    t.text "address_line1"
    t.text "address_line2"
    t.text "address_city"
    t.text "address_state"
    t.text "address_postal_code"
    t.text "stripe_customer_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "slug"
    t.index ["event_id"], name: "index_sponsors_on_event_id"
    t.index ["slug"], name: "index_sponsors_on_slug", unique: true
  end

  create_table "stripe_ach_payment_sources", force: :cascade do |t|
    t.text "stripe_source_id"
    t.text "stripe_customer_id"
    t.text "account_number_ciphertext"
    t.text "routing_number_ciphertext"
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_stripe_ach_payment_sources_on_event_id"
    t.index ["stripe_source_id"], name: "index_stripe_ach_payment_sources_on_stripe_source_id", unique: true
  end

  create_table "stripe_authorizations", force: :cascade do |t|
    t.text "stripe_id"
    t.integer "stripe_status"
    t.integer "authorization_method"
    t.boolean "approved", default: false, null: false
    t.bigint "stripe_card_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "display_name"
    t.datetime "marked_no_or_lost_receipt_at", precision: nil
    t.index ["stripe_card_id"], name: "index_stripe_authorizations_on_stripe_card_id"
  end

  create_table "stripe_cardholders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "stripe_id"
    t.text "stripe_billing_address_line1"
    t.text "stripe_billing_address_line2"
    t.text "stripe_billing_address_city"
    t.text "stripe_billing_address_country"
    t.text "stripe_billing_address_postal_code"
    t.text "stripe_billing_address_state"
    t.text "stripe_name"
    t.text "stripe_email"
    t.text "stripe_phone_number"
    t.integer "cardholder_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_id"], name: "index_stripe_cardholders_on_stripe_id"
    t.index ["user_id"], name: "index_stripe_cardholders_on_user_id"
  end

  create_table "stripe_cards", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "stripe_cardholder_id", null: false
    t.text "stripe_id"
    t.text "stripe_brand"
    t.integer "stripe_exp_month"
    t.integer "stripe_exp_year"
    t.text "last4"
    t.integer "card_type", default: 0, null: false
    t.text "stripe_status"
    t.text "stripe_shipping_address_city"
    t.text "stripe_shipping_address_country"
    t.text "stripe_shipping_address_line1"
    t.text "stripe_shipping_address_postal_code"
    t.text "stripe_shipping_address_line2"
    t.text "stripe_shipping_address_state"
    t.text "stripe_shipping_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "purchased_at", precision: nil
    t.integer "spending_limit_interval"
    t.integer "spending_limit_amount"
    t.boolean "activated", default: false
    t.bigint "replacement_for_id"
    t.string "name"
    t.index ["event_id"], name: "index_stripe_cards_on_event_id"
    t.index ["replacement_for_id"], name: "index_stripe_cards_on_replacement_for_id"
    t.index ["stripe_cardholder_id"], name: "index_stripe_cards_on_stripe_cardholder_id"
  end

  create_table "tags", force: :cascade do |t|
    t.text "label"
    t.text "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_id", null: false
    t.index ["event_id"], name: "index_tags_on_event_id"
  end

  create_table "tours", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.string "tourable_type", null: false
    t.bigint "tourable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "step", default: 0
    t.index ["tourable_type", "tourable_id"], name: "index_tours_on_tourable"
  end

  create_table "transaction_csvs", force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.text "plaid_id"
    t.text "transaction_type"
    t.text "plaid_category_id"
    t.text "name"
    t.bigint "amount"
    t.date "date"
    t.text "location_address"
    t.text "location_city"
    t.text "location_state"
    t.text "location_zip"
    t.decimal "location_lat"
    t.decimal "location_lng"
    t.text "payment_meta_reference_number"
    t.text "payment_meta_ppd_id"
    t.boolean "pending"
    t.text "pending_transaction_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "bank_account_id"
    t.text "payment_meta_by_order_of"
    t.text "payment_meta_payee"
    t.text "payment_meta_payer"
    t.text "payment_meta_payment_method"
    t.text "payment_meta_payment_processor"
    t.text "payment_meta_reason"
    t.bigint "fee_relationship_id"
    t.datetime "deleted_at", precision: nil
    t.boolean "is_event_related"
    t.bigint "emburse_transfer_id"
    t.bigint "invoice_payout_id"
    t.text "slug"
    t.text "display_name"
    t.bigint "fee_reimbursement_id"
    t.bigint "check_id"
    t.bigint "ach_transfer_id"
    t.bigint "donation_payout_id"
    t.bigint "disbursement_id"
    t.index ["ach_transfer_id"], name: "index_transactions_on_ach_transfer_id"
    t.index ["bank_account_id"], name: "index_transactions_on_bank_account_id"
    t.index ["check_id"], name: "index_transactions_on_check_id"
    t.index ["deleted_at"], name: "index_transactions_on_deleted_at"
    t.index ["disbursement_id"], name: "index_transactions_on_disbursement_id"
    t.index ["donation_payout_id"], name: "index_transactions_on_donation_payout_id"
    t.index ["emburse_transfer_id"], name: "index_transactions_on_emburse_transfer_id"
    t.index ["fee_reimbursement_id"], name: "index_transactions_on_fee_reimbursement_id"
    t.index ["fee_relationship_id"], name: "index_transactions_on_fee_relationship_id"
    t.index ["invoice_payout_id"], name: "index_transactions_on_invoice_payout_id"
    t.index ["plaid_id"], name: "index_transactions_on_plaid_id", unique: true
    t.index ["slug"], name: "index_transactions_on_slug", unique: true
  end

  create_table "twilio_messages", force: :cascade do |t|
    t.text "from"
    t.text "to"
    t.text "body"
    t.text "twilio_sid"
    t.text "twilio_account_sid"
    t.jsonb "raw_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fingerprint"
    t.string "device_info"
    t.string "os_info"
    t.string "timezone"
    t.string "ip"
    t.datetime "deleted_at", precision: nil
    t.bigint "impersonated_by_id"
    t.boolean "peacefully_expired"
    t.decimal "latitude"
    t.decimal "longitude"
    t.bigint "webauthn_credential_id"
    t.datetime "expiration_at", precision: nil, null: false
    t.text "session_token_ciphertext"
    t.string "session_token_bidx"
    t.index ["impersonated_by_id"], name: "index_user_sessions_on_impersonated_by_id"
    t.index ["session_token_bidx"], name: "index_user_sessions_on_session_token_bidx"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
    t.index ["webauthn_credential_id"], name: "index_user_sessions_on_webauthn_credential_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "email"
    t.string "full_name"
    t.text "phone_number"
    t.datetime "admin_at", precision: nil
    t.string "slug"
    t.boolean "pretend_is_not_admin", default: false, null: false
    t.boolean "sessions_reported", default: false, null: false
    t.boolean "phone_number_verified", default: false
    t.boolean "use_sms_auth", default: false
    t.string "webauthn_id"
    t.integer "session_duration_seconds", default: 2592000, null: false
    t.date "birthday"
    t.string "api_access_token_bidx"
    t.text "api_access_token_ciphertext"
    t.boolean "seasonal_themes_enabled", default: true, null: false
    t.datetime "locked_at", precision: nil
    t.index ["api_access_token_bidx"], name: "index_users_on_api_access_token_bidx", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.datetime "created_at", precision: nil
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "webauthn_id"
    t.string "public_key"
    t.integer "sign_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "authenticator_type"
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "ach_payments", "stripe_ach_payment_sources"
  add_foreign_key "ach_transfers", "events"
  add_foreign_key "ach_transfers", "users", column: "creator_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_fees", "events"
  add_foreign_key "canonical_event_mappings", "canonical_transactions"
  add_foreign_key "canonical_event_mappings", "events"
  add_foreign_key "canonical_hashed_mappings", "canonical_transactions"
  add_foreign_key "canonical_hashed_mappings", "hashed_transactions"
  add_foreign_key "canonical_pending_declined_mappings", "canonical_pending_transactions"
  add_foreign_key "canonical_pending_event_mappings", "canonical_pending_transactions"
  add_foreign_key "canonical_pending_event_mappings", "events"
  add_foreign_key "canonical_pending_settled_mappings", "canonical_pending_transactions"
  add_foreign_key "canonical_pending_settled_mappings", "canonical_transactions"
  add_foreign_key "canonical_pending_transactions", "raw_pending_stripe_transactions"
  add_foreign_key "checks", "lob_addresses"
  add_foreign_key "checks", "users", column: "creator_id"
  add_foreign_key "disbursements", "events"
  add_foreign_key "disbursements", "events", column: "source_event_id"
  add_foreign_key "disbursements", "users", column: "fulfilled_by_id"
  add_foreign_key "disbursements", "users", column: "requested_by_id"
  add_foreign_key "document_downloads", "documents"
  add_foreign_key "document_downloads", "users"
  add_foreign_key "documents", "events"
  add_foreign_key "documents", "users"
  add_foreign_key "donations", "donation_payouts", column: "payout_id"
  add_foreign_key "donations", "events"
  add_foreign_key "donations", "fee_reimbursements"
  add_foreign_key "emburse_card_requests", "emburse_cards"
  add_foreign_key "emburse_card_requests", "events"
  add_foreign_key "emburse_card_requests", "users", column: "creator_id"
  add_foreign_key "emburse_card_requests", "users", column: "fulfilled_by_id"
  add_foreign_key "emburse_cards", "events"
  add_foreign_key "emburse_cards", "users"
  add_foreign_key "emburse_transactions", "emburse_cards"
  add_foreign_key "emburse_transactions", "events"
  add_foreign_key "emburse_transfers", "emburse_cards"
  add_foreign_key "emburse_transfers", "events"
  add_foreign_key "emburse_transfers", "users", column: "creator_id"
  add_foreign_key "emburse_transfers", "users", column: "fulfilled_by_id"
  add_foreign_key "events", "partners"
  add_foreign_key "events", "users", column: "point_of_contact_id"
  add_foreign_key "exports", "users"
  add_foreign_key "fee_relationships", "events"
  add_foreign_key "fees", "canonical_event_mappings"
  add_foreign_key "g_suite_accounts", "g_suites"
  add_foreign_key "g_suite_accounts", "users", column: "creator_id"
  add_foreign_key "g_suites", "events"
  add_foreign_key "g_suites", "users", column: "created_by_id"
  add_foreign_key "hashed_transactions", "raw_plaid_transactions"
  add_foreign_key "invoices", "fee_reimbursements"
  add_foreign_key "invoices", "invoice_payouts", column: "payout_id"
  add_foreign_key "invoices", "sponsors"
  add_foreign_key "invoices", "users", column: "archived_by_id"
  add_foreign_key "invoices", "users", column: "creator_id"
  add_foreign_key "invoices", "users", column: "manually_marked_as_paid_user_id"
  add_foreign_key "lob_addresses", "events"
  add_foreign_key "login_tokens", "user_sessions"
  add_foreign_key "login_tokens", "users"
  add_foreign_key "mfa_requests", "mfa_codes"
  add_foreign_key "ops_checkins", "users", column: "point_of_contact_id"
  add_foreign_key "organizer_position_deletion_requests", "organizer_positions"
  add_foreign_key "organizer_position_deletion_requests", "users", column: "closed_by_id"
  add_foreign_key "organizer_position_deletion_requests", "users", column: "submitted_by_id"
  add_foreign_key "organizer_position_invites", "events"
  add_foreign_key "organizer_position_invites", "organizer_positions"
  add_foreign_key "organizer_position_invites", "users"
  add_foreign_key "organizer_position_invites", "users", column: "sender_id"
  add_foreign_key "organizer_positions", "events"
  add_foreign_key "organizer_positions", "users"
  add_foreign_key "partner_donations", "events"
  add_foreign_key "partnered_signups", "events"
  add_foreign_key "partnered_signups", "partners"
  add_foreign_key "partnered_signups", "users"
  add_foreign_key "partners", "users", column: "representative_id"
  add_foreign_key "raw_pending_incoming_disbursement_transactions", "disbursements"
  add_foreign_key "raw_pending_outgoing_disbursement_transactions", "disbursements"
  add_foreign_key "receipts", "users"
  add_foreign_key "recurring_donations", "events"
  add_foreign_key "sponsors", "events"
  add_foreign_key "stripe_ach_payment_sources", "events"
  add_foreign_key "stripe_authorizations", "stripe_cards"
  add_foreign_key "stripe_cardholders", "users"
  add_foreign_key "stripe_cards", "events"
  add_foreign_key "stripe_cards", "stripe_cardholders"
  add_foreign_key "transactions", "ach_transfers"
  add_foreign_key "transactions", "bank_accounts"
  add_foreign_key "transactions", "checks"
  add_foreign_key "transactions", "disbursements"
  add_foreign_key "transactions", "donation_payouts"
  add_foreign_key "transactions", "emburse_transfers"
  add_foreign_key "transactions", "fee_reimbursements"
  add_foreign_key "transactions", "fee_relationships"
  add_foreign_key "transactions", "invoice_payouts"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "user_sessions", "users", column: "impersonated_by_id"
  add_foreign_key "webauthn_credentials", "users"
end
