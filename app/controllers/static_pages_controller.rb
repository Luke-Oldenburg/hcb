class StaticPagesController < ApplicationController
  skip_after_action :verify_authorized # do not force pundit
  skip_before_action :signed_in_user, only: [:stats, :branding, :faq]

  def index
    if signed_in?
      @events = current_user.events
      @invites = current_user.organizer_position_invites.pending

      if @events.size == 1 && @invites.size == 0 && !admin_signed_in?
        redirect_to current_user.events.first
      end
    end
    if admin_signed_in?
      @transaction_volume = Transaction.total_volume
      @active = {
        card_requests: CardRequest.under_review.size,
        # These don't need to be merged, as they are mutually exclusive sets
        checks: Check.pending.size + Check.unfinished_void.size,
        ach_transfers: AchTransfer.pending.size,
        pending_fees: Event.pending_fees.size,
        negative_events: Event.negatives.size,
        fee_reimbursements: FeeReimbursement.unprocessed.size,
        load_card_requests: LoadCardRequest.under_review.size,
        g_suite_applications: GSuiteApplication.under_review.size,
        g_suite_accounts: GSuiteAccount.under_review.size,
        transactions: Transaction.needs_action.size,
        emburse_transactions: EmburseTransaction.under_review.size,
        disbursements: Disbursement.pending.size,
        organizer_position_deletion_requests: OrganizerPositionDeletionRequest.under_review.size
      }
    end
  end

  def pending_fees
    @pending_fees = Event.pending_fees.sort_by { |event| (DateTime.now - event.transactions.first.date) }.reverse
  end

  def pending_disbursements
    @pending_disbursements = Disbursement.pending
  end

  def branding
    @logos = [
      { name: 'Original Light', criteria: 'For white or light colored backgrounds.', background: 'smoke' },
      { name: 'Original Dark', criteria: 'For black or dark colored backgrounds.', background: 'black' },
      { name: 'Outlined Black', criteria: 'For white or light colored backgrounds.', background: 'snow' },
      { name: 'Outlined White', criteria: 'For black or dark colored backgrounds.', background: 'black' }
    ]
    @event_name = signed_in? && current_user.events.first ? current_user.events.first.name : 'Hack Pennsylvania'
  end

  def search
    # allows the same URL to easily be used for form and GET
    return if request.method == 'GET'
    
    # removing dashes to deal with phone number
    query = params[:q].gsub('-', '').strip

    users = []

    users.push(User.where("full_name ilike ?", "%#{query.downcase}%"))
    users.push(User.where(email: query))
    users.push(User.where(phone_number: query))

    @result = users.flatten.compact
  end

  def faq
  end

  def negative_events
    @negative_events = Event.negatives
  end

  def stats
    events_list = []
    Event.order(created_at: :desc).limit(10).each { |event|
      events_list.push({
        created_at: event.created_at.to_i, # unix timestamp
      })
    }

    now = DateTime.current
    year_ago = now - 1.year
    qtr_ago = now - 3.month
    month_ago = now - 1.month

    # NOTE: These stats are consumed by the hackclub/goblin
    # slack bot, and modifying the JSON schema without updating the bot
    # MAY BREAK THE BOT. - @thesephist
    render json: {
      transactions_volume: Transaction.total_volume,
      transactions_count: Transaction.all.size,
      events_count: Event.all.size,
      # Transactions are sorted by date DESC by default, so first one is... chronologically last
      last_transaction_date: Transaction.first.created_at.to_i,
      raised: Transaction.raised_during(DateTime.strptime('0', '%s'), now),
      last_year: {
        transactions_volume: Transaction.volume_during(year_ago, now),
        revenue: Transaction.revenue_during(year_ago, now),
        raised: Transaction.raised_during(year_ago, now),
      },
      last_qtr: {
        transactions_volume: Transaction.volume_during(qtr_ago, now),
        revenue: Transaction.revenue_during(qtr_ago, now),
        raised: Transaction.raised_during(qtr_ago, now),
      },
      last_month: {
        transactions_volume: Transaction.volume_during(month_ago, now),
        revenue: Transaction.revenue_during(month_ago, now),
        raised: Transaction.raised_during(month_ago, now),
      },
      events: events_list,
    }
  end
end
