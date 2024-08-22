# frozen_string_literal: true

class EventsController < ApplicationController
  TRANSACTIONS_PER_PAGE = 75

  include SetEvent

  include Rails::Pagination
  before_action :set_event, except: [:index, :new, :create, :by_airtable_id]
  before_action except: [:show, :index] do
    render_back_to_tour @organizer_position, :welcome, event_path(@event)
  end
  skip_before_action :signed_in_user
  before_action :set_mock_data

  before_action :redirect_to_onboarding, unless: -> { @event&.is_public? }

  # GET /events
  def index
    authorize Event
    respond_to do |format|
      format.json do
        events = @current_user.events.with_attached_logo.reorder("organizer_positions.sort_index ASC", "events.id ASC").map { |x|
          {
            name: x.name,
            slug: x.slug,
            category: x.category,
            logo: x.logo.attached? ? Rails.application.routes.url_helpers.url_for(x.logo) : "none",
            demo_mode: x.demo_mode,
            member: true
          }
        }

        if admin_signed_in?
          events.concat(
            Event.not_demo_mode.excluding(@current_user.events).with_attached_logo.select([:slug, :name, :category]).map { |e|
              {
                slug: e.slug,
                name: e.name,
                category: e.category,
                logo: e.logo.attached? ? Rails.application.routes.url_helpers.url_for(e.logo) : "none",
                demo_mode: false,
                member: false
              }
            }
          )
        end

        response.content_type = "text/json"

        render json: events
      end
      format.html { redirect_to root_path }
    end
  end

  # GET /events/1
  def show
    authorize @event

    @pending_transactions = _show_pending_transactions.first(5)
    @canonical_transactions = TransactionGroupingEngine::Transaction::All.new(event_id: @event.id).run.first(5)
    all_transactions = [*@pending_transactions, *@canonical_transactions]

    filter_and_sort = lambda do |transactions, &filter|
      transactions
        .select(&filter)
        .sort_by { |t| t.date.is_a?(String) ? Date.parse(t.date) : t.date }
        .reverse
        .first(5)
    end

    @recent_transactions = all_transactions.first(5)
    @money_in = filter_and_sort.call(all_transactions) { |t| t.amount_cents > 0 }
    @money_out = filter_and_sort.call(all_transactions) { |t| t.amount_cents < 0 }

    @activities = PublicActivity::Activity.for_event(@event).order(created_at: :desc).first(5)
    @organizers = @event.organizer_positions.includes(:user).order(created_at: :desc)
    @cards = all_stripe_cards = @event.stripe_cards.order(created_at: :desc).where(stripe_cardholder: current_user&.stripe_cardholder).first(10)
  end

  def transaction_heatmap
    authorize @event
    heatmap_engine_response = BreakdownEngine::Heatmap.new(@event).run

    @heatmap = heatmap_engine_response[:heatmap]
    @maximum_positive_change = heatmap_engine_response[:maximum_positive_change]
    @maximum_negative_change = heatmap_engine_response[:maximum_negative_change]
    @past_year_transactions_count = heatmap_engine_response[:transactions_count]

    respond_to do |format|
      format.html { render partial: "events/home/heatmap", locals: { heatmap: @heatmap, event: @event } }
    end
  end

  def top_merchants
    authorize @event
    @merchants = BreakdownEngine::Merchants.new(@event).run
    respond_to do |format|
      format.html { render partial: "events/home/top_merchants", locals: { merchants: @merchants, event: @event } }
    end
  end

  def top_categories
    authorize @event
    @categories = BreakdownEngine::Categories.new(@event).run
    respond_to do |format|
      format.html { render partial: "events/home/top_categories", locals: { categories: @categories, event: @event } }
    end
  end

  def tags_users
    authorize @event
    @users = BreakdownEngine::Users.new(@event).run
    @tags = BreakdownEngine::Tags.new(@event).run
    respond_to do |format|
      format.html { render partial: "events/home/tags_users", locals: { users: @users, tags: @tags, event: @event } }
    end
  end

  def transactions
    render_tour @organizer_position, :welcome

    maybe_pending_invite = OrganizerPositionInvite.pending.find_by(user: current_user, event: @event)

    if maybe_pending_invite.present?
      skip_authorization
      return redirect_to maybe_pending_invite
    end

    begin
      authorize @event
    rescue Pundit::NotAuthorizedError
      return redirect_to root_path, flash: { error: "We couldn’t find that organization!" }
    end

    # The search query name was historically `search`. It has since been renamed
    # to `q`. This following line retains backwards compatibility.
    params[:q] ||= params[:search]

    if params[:tag] && Flipper.enabled?(:transaction_tags_2022_07_29, @event)
      @tag = Tag.find_by(event_id: @event.id, label: params[:tag])
    end

    @user = User.find(params[:user]) if params[:user]

    @type = params[:type]
    @start_date = params[:start].presence
    @end_date = params[:end].presence
    @minimum_amount = params[:minimum_amount].presence ? Money.from_amount(params[:minimum_amount].to_f) : nil
    @maximum_amount = params[:maximum_amount].presence ? Money.from_amount(params[:maximum_amount].to_f) : nil

    @organizers = @event.organizer_positions.includes(:user).order(created_at: :desc)
    @pending_transactions = _show_pending_transactions

    if !signed_in? && !@event.holiday_features
      @hide_seasonal_decorations = true
    end

    @all_transactions = TransactionGroupingEngine::Transaction::All.new(
      event_id: @event.id,
      search: params[:q],
      tag_id: @tag&.id,
      minimum_amount: @minimum_amount,
      maximum_amount: @maximum_amount,
      user: @user,
      start_date: @start_date,
      end_date: @end_date
    ).run

    @type_filters = {
      "ach_transfer"           => {
        "settled" => ->(t) { t.local_hcb_code.ach_transfer? },
        "pending" => ->(t) { t.raw_pending_outgoing_ach_transaction_id },
        "icon"    => "plus-fill"
      },
      "mailed_check"           => {
        "settled" => ->(t) { t.local_hcb_code.check? || t.local_hcb_code.increase_check? },
        "pending" => ->(t) { t.raw_pending_outgoing_check_transaction_id || t.increase_check_id },
        "icon"    => "payment-transfer"
      },
      "account_transfer"       => {
        "settled" => ->(t) { t.local_hcb_code.disbursement? },
        "pending" => ->(t) { t.local_hcb_code.disbursement? },
        "icon"    => "door-enter"
      },
      "card_charge"            => {
        "settled" => ->(t) { t.raw_stripe_transaction },
        "pending" => ->(t) { t.raw_pending_stripe_transaction_id },
        "icon"    => "card"
      },
      "check_deposit"          => {
        "settled" => ->(t) { t.local_hcb_code.check_deposit? },
        "pending" => ->(t) { t.check_deposit_id },
        "icon"    => "payment-docs"
      },
      "donation"               => {
        "settled" => ->(t) { t.local_hcb_code.donation? },
        "pending" => ->(t) { t.raw_pending_donation_transaction_id },
        "icon"    => "support"
      },
      "invoice"                => {
        "settled" => ->(t) { t.local_hcb_code.invoice? },
        "pending" => ->(t) { t.raw_pending_invoice_transaction_id },
        "icon"    => "briefcase"
      },
      "refund"                 => {
        "settled" => ->(t) { t.local_hcb_code.stripe_refund? },
        "pending" => ->(t) { false },
        "icon"    => "view-reload"
      },
      "fiscal_sponsorship_fee" => {
        "settled" => ->(t) { t.local_hcb_code.fee_revenue? || t.fee_payment? },
        "pending" => ->(t) { t.raw_pending_bank_fee_transaction_id },
        "icon"    => "minus-fill"
      },
      "reimbursement"          => {
        "settled" => ->(t) { t.local_hcb_code.reimbursement_expense_payout? },
        "pending" => ->(t) { false },
        "icon"    => "minus-fill"
      }
    }

    if @type
      filter = @type_filters[@type]
      if filter
        @all_transactions = @all_transactions.select(&filter["settled"])
        @pending_transactions = @pending_transactions.select(&filter["pending"])
      end
    end

    page = (params[:page] || 1).to_i
    per_page = (params[:per] || TRANSACTIONS_PER_PAGE).to_i

    @transactions = Kaminari.paginate_array(@all_transactions).page(page).per(per_page)
    TransactionGroupingEngine::Transaction::AssociationPreloader.new(transactions: @transactions, event: @event).run!

    if show_running_balance?
      offset = page * per_page

      initial_subtotal = if @all_transactions.count > offset
                           TransactionGroupingEngine::Transaction::RunningBalanceAssociationPreloader.new(transactions: @all_transactions, event: @event).run!
                           # sum up transactions on pages after this one to get the initial subtotal
                           @all_transactions.slice(offset...).map(&:amount).sum
                         else
                           # this is the last page, so start from 0
                           0
                         end

      @transactions.reverse.reduce(initial_subtotal) do |running_total, transaction|
        transaction.running_balance = running_total + transaction.amount
      end
    end

    if helpers.show_mock_data?
      @transactions = MockTransactionEngineService::GenerateMockTransaction.new.run

      @transactions = Kaminari.paginate_array(@transactions).page(params[:page]).per(params[:per] || 75)
      @mock_total = @transactions.sum(&:amount_cents)
    end

    if current_user && !Flipper.enabled?(:native_changelog_2024_07_03, current_user)
      @latest_changelog_post = ChangelogPost.latest
      Flipper.enable(:native_changelog_2024_07_03, current_user)
    end

    if current_user && !Flipper.enabled?(:the_bin_popup_2024_05_17, current_user) && @event.robotics_team? && !@first_time
      Flipper.enable_actor(:the_bin_popup_2024_05_17, current_user)
      @the_bin = true
    end

    if flash[:popover]
      @popover = flash[:popover]
      flash.delete(:popover)
    end
  end

  def balance_by_date
    authorize @event

    max = [365, (Date.today - @event.created_at.to_date).to_i + 5].min

    balance_by_date = Rails.cache.fetch("balance_by_date_#{@event.id}", expires_in: 5.minutes) do
      ::TransactionGroupingEngine::Transaction::All.new(event_id: @event.id).running_balance_by_date
    end

    balance_by_date[0.days.ago.to_date] = @event.balance_v2_cents

    begin
      if (balance_by_date[max.days.ago.to_date] || balance_by_date[balance_by_date.keys.first]) > balance_by_date[0.days.ago.to_date]
        balance_trend = "down"
      else
        balance_trend = "up"
      end
    rescue
      balance_trend = "up"
    end

    render json: {
      balanceByDate: balance_by_date,
      balanceTrend: balance_trend
    }
  end

  # GET /event_by_airtable_id/recABC
  def by_airtable_id
    authorize Event
    @event = Event.find_by(club_airtable_id: params[:airtable_id])

    if @event.nil?
      flash[:error] = "We couldn’t find that event!"
      redirect_to root_path
    else
      redirect_to @event
    end
  end

  def team
    authorize @event

    case params[:filter]
    when "members"
      @filter = "member"
    when "managers"
      @filter = "manager"
    end

    @q = params[:q] || ""

    @all_positions = @event.organizer_positions
                           .joins(:user)
                           .where(role: @filter || %w[member manager])
                           .where("users.full_name ILIKE :query OR users.email ILIKE :query", query: "%#{User.sanitize_sql_like(@q)}%")
                           .order(created_at: :desc)

    @positions = Kaminari.paginate_array(@all_positions).page(params[:page]).per(params[:per] || params[:view] == "list" ? 20 : 10)

    @pending = @event.organizer_position_invites.pending.includes(:sender)
  end

  # GET /events/1/edit
  def edit
    @settings_tab = params[:tab]
    authorize @event
    @activities = PublicActivity::Activity.for_event(@event).order(created_at: :desc).page(params[:page]).per(25) if @settings_tab == "audit_log"

    render :edit, layout: !params[:frame]
  end

  # PATCH/PUT /events/1
  def update
    authorize @event

    # have to use `fixed_event_params` because `event_params` seems to be a constant
    fixed_event_params = event_params
    fixed_user_event_params = user_event_params

    fixed_event_params[:club_airtable_id] = nil if event_params.key?(:club_airtable_id) && event_params[:club_airtable_id].empty?

    # processing hidden for admins
    if fixed_event_params[:hidden] == "1" && !@event.hidden_at.present?
      fixed_event_params[:hidden_at] = DateTime.now
    elsif fixed_event_params[:hidden] == "0" && @event.hidden_at.present?
      fixed_event_params[:hidden_at] = nil
    end
    fixed_event_params.delete(:hidden)

    # processing hidden for users
    if fixed_user_event_params[:hidden] == "1" && !@event.hidden_at.present?
      fixed_user_event_params[:hidden_at] = DateTime.now
    elsif fixed_user_event_params[:hidden] == "0" && @event.hidden_at.present?
      fixed_user_event_params[:hidden_at] = nil
    end
    fixed_user_event_params.delete(:hidden)

    if @event.update(current_user.admin? ? fixed_event_params : fixed_user_event_params)
      flash[:success] = "Organization successfully updated."
      redirect_back fallback_location: edit_event_path(@event.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def finish_signee_backfill
    authorize @event
    if @event.organizer_positions.where(is_signee: nil).update(is_signee: false)
      flash[:success] = "Wow-e! It's done... the signee backfill that is."
    else
      flash[:error] = "WHAT?! An error. Go pester @sampoder."
    end
    redirect_back fallback_location: event_team_path(@event.slug)
  end

  # DELETE /events/1
  def destroy
    authorize @event

    @event.destroy
    flash[:success] = "Organization successfully deleted."
    redirect_to root_path
  end

  def emburse_card_overview
    authorize @event
    @emburse_cards = @event.emburse_cards.includes(user: [:profile_picture_attachment])
    @emburse_card_requests = @event.emburse_card_requests.includes(creator: :profile_picture_attachment)
    @emburse_transfers = @event.emburse_transfers
    @emburse_transactions = @event.emburse_transactions.order(transaction_time: :desc).where.not(transaction_time: nil).includes(:emburse_card)

    @sum = @event.emburse_balance
  end

  def card_overview
    @status = %w[virtual physical active inactive].include?(params[:status]) ? params[:status] : nil

    @user_id = params[:user].presence
    @user = User.find(params[:user]) if params[:user]

    all_stripe_cards = @event.stripe_cards.where.missing(:card_grant).joins(:stripe_cardholder, :user)
                             .order("stripe_status asc, created_at desc")

    all_stripe_cards = all_stripe_cards.where(user: { id: @user_id }) if @user_id

    all_stripe_cards = case @status
                       when "active"
                         all_stripe_cards.active
                       when "inactive"
                         all_stripe_cards.deactivated
                       when "virtual"
                         all_stripe_cards.virtual
                       when "physical"
                         all_stripe_cards.physical
                       else
                         all_stripe_cards
                       end

    if current_user.present?
      @stripe_cards = all_stripe_cards.where.not(stripe_cardholder: current_user.stripe_cardholder)
      @user_stripe_cards = all_stripe_cards.where(stripe_cardholder: current_user.stripe_cardholder)
    else
      @stripe_cards = all_stripe_cards
      @user_stripe_cards = StripeCard.none
    end

    @stripe_cardholders = StripeCardholder.where(user_id: @event.users.pluck(:id)).includes(:user).order("created_at desc")
    @organizer_position = OrganizerPosition.find_by(event: @event, user: current_user)

    authorize @event

    # Generate mock data
    if helpers.show_mock_data?
      @user_stripe_cards = []

      if organizer_signed_in?
        # The user's cards
        2.times.each_with_index do |_, i|
          state = i > 0
          virtual = rand > 0.5
          card = OpenStruct.new(
            id: Faker::Number.number(digits: 1),
            virtual?: virtual,
            physical?: !virtual,
            remote_shipping_status: rand > 0.5 ? "PENDING" : "SHIPPED",
            created_at: Faker::Time.between(from: 1.year.ago, to: Time.now),
            state: state ? "success" : "muted",
            state_text: state ? "Active" : "Frozen",
            status_text: state ? "Active" : "Frozen",
            stripe_name: current_user.name,
            user: current_user,
            formatted_card_number: Faker::Finance.credit_card(:mastercard),
            hidden_card_number: "•••• •••• •••• ••••",
            hidden_card_number_with_last_four: "•••• •••• •••• #{Faker::Number.number(digits: 4)}",
            to_partial_path: "stripe_cards/stripe_card",
          )
          @user_stripe_cards << card
        end
      end
      # Sort by date issued
      @user_stripe_cards.sort_by! { |card| card.created_at }.reverse!
    end

    page = (params[:page] || 1).to_i
    per_page = (params[:per] || 20).to_i

    display_cards = if helpers.show_mock_data? && organizer_signed_in?
                      @user_stripe_cards
                    elsif helpers.show_mock_data?
                      []
                    else
                      [
                        @user_stripe_cards.active,
                        @stripe_cards.active,
                        @user_stripe_cards.deactivated,
                        @stripe_cards.deactivated
                      ].flatten
                    end

    @paginated_stripe_cards = Kaminari.paginate_array(display_cards).page(page).per(per_page)
    @all_unique_cardholders = @event.stripe_cards.map(&:stripe_cardholder).uniq

  end

  def documentation
    @event_name = @event.name

    authorize @event
  end

  def async_balance
    authorize @event

    render :async_balance, layout: false
  end

  # (@msw) these pages are for the WIP resources page.
  def connect_gofundme
    @event_name = @event.name
    @document_title = "Connect a GoFundMe Campaign"
    @document_subtitle = "Receive payouts from GoFundMe directly into HCB"
    @document_image = "https://cloud-jl944nr65-hack-club-bot.vercel.app/004e072bbe1.png"
    authorize @event
  end

  # (@msw) these pages are for the WIP resources page.
  def sell_merch
    event_name = @event.name
    @document_title = "Sell Merch with Redbubble"
    @document_subtitle = "Connect your online merch shop to HCB"
    @document_image = "https://cloud-fodxc88eu-hack-club-bot.vercel.app/0placeholder.png"
    authorize @event
  end

  def account_number
    @transactions = if @event.column_account_number.present?
                      CanonicalTransaction.where(transaction_source_type: "RawColumnTransaction", transaction_source_id: RawColumnTransaction.where("column_transaction->>'account_number_id' = '#{@event.column_account_number.column_id}'").pluck(:id)).order(created_at: :desc)
                    else
                      CanonicalTransaction.none
                    end
    page = (params[:page] || 1).to_i
    @transactions = @transactions.page(page).per(params[:per] || 25)
    authorize @event
  end

  def g_suite_overview
    authorize @event

    @g_suite = @event.g_suites.first
    @waitlist_form_submitted = GWaitlistTable.all(filter: "{OrgID} = '#{@event.id}'").any? unless Flipper.enabled?(:google_workspace, @event)

    # this is janky and should be fixed at some point!
    # for more context on what this is:
    # result[0] = verification key
    # result[1] = spf
    # result[2] = mx1
    # result[3] = mx2
    # result[4] = mx3
    # result[5] = mx4
    # result[6] = mx5
    @result = [false, false, false, false, false, false, false]

    if @g_suite&.verification_error?
      Resolv::DNS.open do |dns|
        records = dns.getresources(@g_suite.domain, Resolv::DNS::Resource::IN::TXT)
        records.each do |record|
          if record.data.include?("google-site-verification=#{@g_suite.verification_key}")
            @result[0] = true
          end
          if record.data.include?("v=spf1") && record.data.include?("include:_spf.google.com")
            @result[1] = true
          end
        end
      end

      mx_records = [
        "ASPMX.L.GOOGLE.COM",
        "ALT1.ASPMX.L.GOOGLE.COM",
        "ALT2.ASPMX.L.GOOGLE.COM",
        "ALT3.ASPMX.L.GOOGLE.COM",
        "ALT4.ASPMX.L.GOOGLE.COM"
      ]

      Resolv::DNS.open do |dns|
        mx_response = dns.getresources(@g_suite.domain, Resolv::DNS::Resource::IN::MX)
        mx_response.each do |record|
          mx_host = record.exchange.to_s.upcase
          index = mx_records.index(mx_host)
          @result[index + 2] = true if index
        end
      end
    end

  end

  def g_suite_create
    authorize @event

    GSuiteService::Create.new(
      current_user:,
      event_id: @event.id,
      domain: params[:domain]
    ).run

    redirect_to event_g_suite_overview_path(event_id: @event.slug)
  rescue => e
    redirect_to event_g_suite_overview_path(event_id: @event.slug), flash: { error: e.message }
  end

  def g_suite_verify
    authorize @event

    GSuiteService::MarkVerifying.new(g_suite_id: @event.g_suites.first.id).run

    redirect_to event_g_suite_overview_path(event_id: @event.slug)
  end

  def donation_overview
    authorize @event

    # The search query name was historically `search`. It has since been renamed
    # to `q`. This following line retains backwards compatibility.
    params[:q] ||= params[:search]

    relation = @event.donations.not_pending.includes(:recurring_donation)

    @stats = {
      deposited: relation.where(aasm_state: [:in_transit, :deposited]).sum(:amount),
    }

    @all_donations = relation.where(aasm_state: [:in_transit, :deposited])

    if params[:filter] == "refunded"
      relation = relation.refunded
    else
      relation = relation.where(aasm_state: [:in_transit, :deposited])
    end

    relation = relation.search_name(params[:q]) if params[:q].present?

    @donations = relation.order(created_at: :desc)

    @recurring_donations = @event.recurring_donations.includes(:donations).active.order(created_at: :desc)

    if helpers.show_mock_data?
      @donations = []
      @recurring_donations = []
      @stats = { deposited: 0, in_transit: 0, refunded: 0 }

      (0..rand(20..50)).each do |_|
        refunded = rand > 0.9
        amount = rand(1..100) * 100
        started_on = Faker::Date.backward(days: 365 * 2)

        donation = OpenStruct.new(
          amount:,
          total_donated: amount * rand(1..5),
          stripe_status: "active",
          state: refunded ? "warning" : "success",
          state_text: refunded ? "Refunded" : "Deposited",
          filter: refunded ? "refunded" : "deposited",
          created_at: started_on,
          name: Faker::Name.name,
          recurring: rand > 0.9,
          local_hcb_code: OpenStruct.new(hashid: ""),
          hcb_code: "",
        )
        @stats[:deposited] += amount unless refunded
        @stats[:refunded] += amount if refunded
        @donations << donation
      end
      @donations.each do |donation|
        if donation[:recurring]
          @recurring_donations << donation
        end
      end
      # Sort by date descending
      @recurring_donations.sort_by! { |invoice| invoice[:created_at] }.reverse!
      @donations.sort_by! { |invoice| invoice[:created_at] }.reverse!
    end

    @recurring_donations_monthly_sum = @recurring_donations.sum(0) { |donation| donation[:amount] }

  end

  def partner_donation_overview
    authorize @event

    relation = @event.partner_donations.not_unpaid

    @stats = {
      deposited: relation.deposited.sum(:payout_amount_cents),
      in_transit: relation.in_transit.sum(:payout_amount_cents),
    }

    relation = relation.pending if params[:filter] == "pending"
    relation = relation.in_transit if params[:filter] == "in_transit"
    relation = relation.deposited if params[:filter] == "deposited"

    @partner_donations = relation.order(created_at: :desc)
  end

  def transfers
    authorize @event

    # The search query name was historically `search`. It has since been renamed
    # to `q`. This following line retains backwards compatibility.
    params[:q] ||= params[:search]

    @ach_transfers = @event.ach_transfers
    @paypal_transfers = @event.paypal_transfers
    @checks = @event.checks.includes(:lob_address)
    @increase_checks = @event.increase_checks
    @disbursements = @event.outgoing_disbursements.includes(:destination_event)
    @card_grants = @event.card_grants.includes(:user, :subledger, :stripe_card)

    @disbursements = @disbursements.not_card_grant_related if Flipper.enabled?(:card_grants_2023_05_25, @event)

    @stats = {
      deposited: @ach_transfers.deposited.sum(:amount) + @checks.deposited.sum(:amount) + @increase_checks.increase_deposited.or(@increase_checks.in_transit).sum(:amount) + @disbursements.fulfilled.pluck(:amount).sum + @paypal_transfers.deposited.sum(:amount_cents),
      in_transit: @ach_transfers.in_transit.sum(:amount) + @checks.in_transit_or_in_transit_and_processed.sum(:amount) + @increase_checks.in_transit.sum(:amount) + @disbursements.reviewing_or_processing.sum(:amount) + @paypal_transfers.approved.or(@paypal_transfers.pending).sum(:amount_cents),
      canceled: @ach_transfers.rejected.sum(:amount) + @checks.canceled.sum(:amount) + @increase_checks.canceled.sum(:amount) + @disbursements.rejected.sum(:amount) + @paypal_transfers.rejected.sum(:amount_cents)
    }

    @ach_transfers = @ach_transfers.in_transit if params[:filter] == "in_transit"
    @ach_transfers = @ach_transfers.deposited if params[:filter] == "deposited"
    @ach_transfers = @ach_transfers.rejected if params[:filter] == "canceled"
    @ach_transfers = @ach_transfers.search_recipient(params[:q]) if params[:q].present?

    @checks = @checks.in_transit_or_in_transit_and_processed if params[:filter] == "in_transit"
    @checks = @checks.deposited if params[:filter] == "deposited"
    @checks = @checks.canceled if params[:filter] == "canceled"
    @checks = @checks.search_recipient(params[:q]) if params[:q].present?

    @increase_checks = @increase_checks.in_transit if params[:filter] == "in_transit"
    @increase_checks = @increase_checks.increase_deposited if params[:filter] == "deposited"
    @increase_checks = @increase_checks.canceled if params[:filter] == "canceled"
    @increase_checks = @increase_checks.search_recipient(params[:q]) if params[:q].present?

    @card_grants = @card_grants.search_recipient(params[:q]) if params[:q].present?

    @disbursements = @disbursements.reviewing_or_processing if params[:filter] == "in_transit"
    @disbursements = @disbursements.fulfilled if params[:filter] == "deposited"
    @disbursements = @disbursements.rejected if params[:filter] == "canceled"
    @disbursements = @disbursements.search_name(params[:q]) if params[:q].present?

    @paypal_transfers = @paypal_transfers.approved.or(@paypal_transfers.pending) if params[:filter] == "in_transit"
    @paypal_transfers = @paypal_transfers.deposited if params[:filter] == "deposited"
    @paypal_transfers = @paypal_transfers.rejected if params[:filter] == "canceled"
    @paypal_transfers = @paypal_transfers.search_recipient(params[:q]) if params[:q].present?

    @transfers = Kaminari.paginate_array((@increase_checks + @checks + @ach_transfers + @disbursements + @card_grants + @paypal_transfers).sort_by { |o| o.created_at }.reverse!).page(params[:page]).per(100)

    # Generate mock data
    if helpers.show_mock_data?
      @transfers = []
      @stats = { deposited: 0, in_transit: 0, canceled: 0 }

      (0..rand(20..100)).each do |_|
        transfer = OpenStruct.new(
          state: "success",
          state_text: rand > 0.5 ? "Fufilled" : "Deposited",
          created_at: Faker::Date.backward(days: 365 * 2),
          amount: rand(1000..10000),
          name: Faker::Name.name,
          hcb_code: "",
        )
        @stats[:deposited] += transfer.amount
        @transfers << transfer
      end
      # Sort by date
      @transfers = @transfers.sort_by { |o| o.created_at }.reverse!

      # Set the most recent 0-3 invoices to be pending
      (0..rand(-1..2)).each do |i|
        @transfers[i].state = "muted"
        @transfers[i].state_text = "Pending"
        @stats[:in_transit] += @transfers[i].amount
      end

      @transfers = Kaminari.paginate_array(@transfers).page(params[:page]).per(100)
    end
  end

  def new_transfer
    authorize @event
  end

  def promotions
    authorize @event
  end

  def expensify
    authorize @event
  end

  def reimbursements
    authorize @event
    @reports = @event.reimbursement_reports
    @reports = @reports.pending if params[:filter] == "pending"
    @reports = @reports.where(aasm_state: ["reimbursement_approved", "reimbursed"]) if params[:filter] == "reimbursed"
    @reports = @reports.rejected if params[:filter] == "rejected"
    @reports = @reports.search(params[:q]) if params[:q].present?
    @reports = @reports.order(created_at: :desc).page(params[:page] || 1).per(params[:per] || 25)
  end

  def reimbursements_pending_review_icon
    authorize @event
    @reimbursements_pending_review_count = @event.reimbursement_reports.submitted.count

    render :reimbursements_pending_review_icon, layout: false
  end

  def toggle_hidden
    authorize @event

    if @event.hidden?
      flash[:success] = "Event un-hidden"
      @event.update(hidden_at: nil)
    else
      @event.update(hidden_at: Time.now)
      file_redirects = [
        "https://cloud-b01qqxaux.vercel.app/barking_dog_turned_into_wood_meme.mp4",
        "https://cloud-b01qqxaux.vercel.app/dog_transforms_after_seeing_chair.mp4",
        "https://cloud-b01qqxaux.vercel.app/dog_turns_into_bread__but_it_s_in_hd.mp4",
        "https://cloud-b01qqxaux.vercel.app/run_now_meme.mp4",
        "https://cloud-3qup26j81.vercel.app/bonk_sound_effect.mp4",
        "https://cloud-is6jebpbb.vercel.app/disappearing_doge_meme.mp4"
      ].sample

      redirect_to file_redirects, allow_other_host: true
    end
  end

  def remove_header_image
    authorize @event

    @event.donation_header_image.purge_later

    redirect_back fallback_location: edit_event_path(@event)
  end

  def remove_background_image
    authorize @event

    @event.background_image.purge_later

    redirect_back fallback_location: edit_event_path(@event)
  end

  def remove_logo
    authorize @event

    @event.logo.purge_later

    redirect_back fallback_location: edit_event_path(@event)
  end

  def toggle_event_tag
    @event_tag = EventTag.find(params[:event_tag_id])

    authorize @event
    authorize @event_tag

    if @event.event_tags.where(id: @event_tag.id).exists?
      @event.event_tags.destroy(@event_tag)
    else
      @event.event_tags << @event_tag
    end

    redirect_back fallback_location: edit_event_path(@event, anchor: "admin_organization_tags")
  end

  def audit_log
    authorize @event
  end

  def statements
    authorize @event

    @start_date = (@event.activated_at || @event.created_at).beginning_of_month.to_date
    @end_date = Date.today.prev_month.beginning_of_month.to_date
  end

  def termination
    authorize @event

    @successor = params[:successor] || "The Hack Foundation"

    @start = params[:start]&.to_datetime || @event.activated_at || @event.created_at

    @end = params[:end]&.to_datetime || Time.now

    respond_to do |format|
      format.html do
        redirect_to @event
      end
      format.pdf do
        render pdf: "Termination Letter for #{@event.name}", page_height: "11in", page_width: "8.5in"
      end
    end
  end

  def validate_slug
    authorize @event

    if params[:value].blank? || params[:value] == @event.slug
      render json: { valid: true }
    elsif @event.tap { |e| e.slug = params[:value] }.valid?
      render json: { valid: true, hint: "This URL is available!" }
    else
      render json: { valid: false, hint: "This URL is unavailable." }
    end
  end

  def activation_flow
    authorize @event
  end

  def activate
    authorize @event

    params[:event][:files]&.each do |file|
      Document.create(user: current_user, event_id: @event.id, name: file.original_filename, file:)
    end

    if @event.update(event_params.except(:files).merge({ demo_mode: false }))
      flash[:success] = "Organization successfully activated."
      redirect_to event_path(@event)
    else
      render :activation_flow, status: :unprocessable_entity
    end
  end

  def claim_point_of_contact
    authorize @event

    if @event.update(point_of_contact: current_user)
      flash[:success] = "You're now the point of contact for #{@event.name}."
    else
      flash[:error] = "Failed to assign you as point of contact."
    end

    redirect_back fallback_location: edit_event_path(@event.slug)
  end

  private

  # Only allow a trusted parameter "white list" through.
  def event_params
    result_params = params.require(:event).permit(
      :name,
      :description,
      :start,
      :end,
      :address,
      :sponsorship_fee,
      :expected_budget,
      :omit_stats,
      :demo_mode,
      :can_front_balance,
      :emburse_department_id,
      :country,
      :postal_code,
      :category,
      :club_airtable_id,
      :point_of_contact_id,
      :slug,
      :hidden,
      :donation_page_enabled,
      :donation_page_message,
      :reimbursements_require_organizer_peer_review,
      :public_reimbursement_page_enabled,
      :public_reimbursement_page_message,
      :donation_thank_you_message,
      :donation_reply_to_email,
      :is_public,
      :is_indexable,
      :holiday_features,
      :public_message,
      :custom_css_url,
      :donation_header_image,
      :logo,
      :website,
      :background_image,
      :stripe_card_shipping_type,
      card_grant_setting_attributes: [
        :merchant_lock,
        :category_lock,
        :invite_message
      ],
      config_attributes: [
        :id,
        :anonymous_donations,
        :cover_donation_fees
      ]
    )

    # Expected budget is in cents on the backend, but dollars on the frontend
    result_params[:expected_budget] = result_params[:expected_budget].to_f * 100 if result_params[:expected_budget]
    # convert whatever the user inputted into something that is a legal slug
    result_params[:slug] = ActiveSupport::Inflector.parameterize(user_event_params[:slug]) if result_params[:slug]

    result_params
  end

  def user_event_params
    result_params = params.require(:event).permit(
      :description,
      :address,
      :slug,
      :hidden,
      :start,
      :end,
      :donation_page_enabled,
      :donation_page_message,
      :reimbursements_require_organizer_peer_review,
      :public_reimbursement_page_enabled,
      :public_reimbursement_page_message,
      :donation_thank_you_message,
      :donation_reply_to_email,
      :is_public,
      :is_indexable,
      :holiday_features,
      :public_message,
      :custom_css_url,
      :donation_header_image,
      :logo,
      :website,
      :background_image,
      card_grant_setting_attributes: [
        :merchant_lock,
        :category_lock,
        :invite_message
      ],
      config_attributes: [
        :id,
        :anonymous_donations,
        :cover_donation_fees
      ]
    )

    # convert whatever the user inputted into something that is a legal slug
    result_params[:slug] = ActiveSupport::Inflector.parameterize(result_params[:slug]) if result_params[:slug]

    result_params
  end

  def _show_pending_transactions
    return [] if params[:page] && params[:page] != "1"
    return [] unless using_transaction_engine_v2? && using_pending_transaction_engine?

    pending_transactions = PendingTransactionEngine::PendingTransaction::All.new(
      event_id: @event.id,
      search: params[:q],
      tag_id: @tag&.id,
      minimum_amount: @minimum_amount,
      maximum_amount: @maximum_amount,
      user: @user,
      start_date: @start_date,
      end_date: @end_date
    ).run
    PendingTransactionEngine::PendingTransaction::AssociationPreloader.new(pending_transactions:, event: @event).run!
    pending_transactions
  end

  def show_running_balance?
    # don't support running balance if tag or search query are present because these filter the query of all transactions, which
    # breaks the running balance computation
    return false if @tag.present?
    return false if params[:q].present?

    @show_running_balance = current_user&.admin? && current_user&.running_balance_enabled?
  end

  def set_mock_data
    if params[:show_mock_data].present?
      helpers.set_mock_data!(params[:show_mock_data] == "true")
    end
  end

end
