class GameTrainCard < ActiveRecord::Base
  STATE_PLAYED = 0
  STATE_ASSIGNED = 1
  STATE_UNASSIGNED = 2
  STATE_FACE_UP = 3

  belongs_to :game
  belongs_to :train_card
  belongs_to :player

  validates_inclusion_of :status, :in => [ STATE_PLAYED, STATE_ASSIGNED, STATE_UNASSIGNED, STATE_FACE_UP ]

  scope :deck_order, -> { order(deck_position: :asc) }
  scope :of_colour, -> (colour) { joins(:train_card).where(train_cards: { colour: colour }) }
  scope :not_of_colour, -> (colour) { joins(:train_card).where.not(train_cards: { colour: colour }) }
  scope :locomotives, -> { of_colour(Colour::NONE) }
  scope :face_up, -> { where(status: STATE_FACE_UP) }
  scope :face_up_card, -> (train_card_id) { face_up.where(train_card_id: train_card_id) }
  scope :with_status, -> (status) { where(status: status) }
  scope :next_deck_card, -> { unassigned.deck_order.limit(1) }
  scope :played, -> { with_status(STATE_PLAYED) }
  scope :unassigned, -> { with_status(STATE_UNASSIGNED) }

  def locomotive?
    train_card.colour == Colour::NONE
  end

  def turn_over!
    self.status = STATE_FACE_UP
  end

  def discard!
    play!
  end

  def play!
    self.player = nil
    self.status = STATE_PLAYED
  end

  def deal_to_player!(player)
    self.player = player
    self.status = STATE_ASSIGNED
  end

  def shuffle_to_position!(position)
    self.player = nil
    self.deck_position = position
    self.status = STATE_UNASSIGNED
  end
end
