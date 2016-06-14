class GameDestinationTicket < ActiveRecord::Base
  STATE_PENDING = 0
  STATE_DISCARDED = 1
  STATE_ASSIGNED = 2
  STATE_UNASSIGNED = 3

  belongs_to :game
  belongs_to :destination_ticket
  belongs_to :player

  validates_inclusion_of :status, :in => [ STATE_PENDING, STATE_DISCARDED, STATE_ASSIGNED, STATE_UNASSIGNED ]

  scope :deck_order, -> { order(deck_position: :asc) }
  scope :with_pending_status, -> { where(status: STATE_PENDING) }
  scope :for_destination_ticket, -> (destination_ticket_id) { where(destination_ticket_id: destination_ticket_id).limit(1) }
  scope :next_deck_ticket, -> { next_deck_tickets(1) }
  scope :with_status, -> (status) { where(status: status) }
  scope :next_deck_tickets, -> (draw_count) { with_status(STATE_UNASSIGNED).deck_order.limit(draw_count) }
  scope :assigned, -> { with_status(STATE_ASSIGNED) }
  scope :unassigned, -> { with_status(STATE_UNASSIGNED) }
  scope :not_assigned, -> { where.not(status: STATE_ASSIGNED) }

  def discard!
    self.player = nil
    self.status = STATE_DISCARDED
  end

  def deal_to_player!(player)
    self.player = player
    self.status = STATE_PENDING
  end

  def assign!
    self.status = STATE_ASSIGNED
  end

  def pending?
    status == STATE_PENDING
  end

  def shuffle_to_position!(position)
    self.deck_position = position
    self.status = STATE_UNASSIGNED
  end

  def self.status_name(val)
    case val
    when STATE_PENDING
      "pending"
    when STATE_DISCARDED
      "played"
    when STATE_ASSIGNED
      "assigned"
    when STATE_UNASSIGNED
      "unassigned"
    else
      raise
    end
  end
end
