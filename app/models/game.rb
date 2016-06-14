class Game < ActiveRecord::Base
  PHASE_SETUP = 0
  PHASE_INITIAL = 1
  PHASE_PLAY = 2
  PHASE_LAST_ROUND = 3
  PHASE_END = 4

  TURN_STATUS_PLAYING = 0
  TURN_STATUS_WAITING_TO_DISCARD = 1
  TURN_STATUS_DRAWING_SECOND_TRAIN_CARD = 2
  TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN = 3

  TRAIN_COUNT_GAME_END_THRESHOLD = 2

  VISIBLE_TRAIN_CARD_COUNT = 5
  MAX_VISIBLE_LOCOMOTIVES = 2

  MIN_PLAYERS = 2
  MAX_PLAYERS = 5

  scope :with_phase, -> (phase) { where phase: phase }

  before_validation { self.phase = PHASE_SETUP if phase.nil?  }

  validates_inclusion_of :phase, :in => [ PHASE_SETUP, PHASE_INITIAL, PHASE_PLAY, PHASE_LAST_ROUND, PHASE_END ]

  validates_inclusion_of :turn_status, :in => [ TURN_STATUS_PLAYING, TURN_STATUS_WAITING_TO_DISCARD, TURN_STATUS_DRAWING_SECOND_TRAIN_CARD, TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN ]

  has_many :players

  has_many :game_destination_tickets
  has_many :destination_tickets, through: :game_destination_tickets

  has_many :game_train_cards
  has_many :train_cards, through: :game_train_cards

  has_many :game_routes
  has_many :routes, through: :game_routes

  belongs_to :turn_player, class_name: 'Player', foreign_key: 'turn_player_id'
  belongs_to :last_player, class_name: 'Player', foreign_key: 'last_player_id'
  belongs_to :winner, class_name: 'Player', foreign_key: 'winning_player_id'

  scope :for_user, -> (user_id) {
    select("distinct games.*")
      .joins("left join players p on p.game_id = games.id")
      .where("((phase = ?) or (p.id is not null AND p.user_id = ?))", PHASE_SETUP, user_id)
  }

  def self.phase_name(phase)
    case phase
    when PHASE_SETUP
      "setup"
    when PHASE_INITIAL
      "initial"
    when PHASE_PLAY
      "play"
    when PHASE_LAST_ROUND
      "final round"
    when PHASE_END
      "end"
    else
      raise
    end
  end

  def self.turn_status_name(turn_status)
    case turn_status
    when TURN_STATUS_PLAYING
      "playing"
    when TURN_STATUS_WAITING_TO_DISCARD
      "waiting to discard destination tickets"
    when TURN_STATUS_DRAWING_SECOND_TRAIN_CARD
      "drawing second train card"
    when TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN
      "waiting for players to join"
    else
      raise
    end
  end

  def update_game_status!
    if [ TURN_STATUS_WAITING_TO_DISCARD, TURN_STATUS_DRAWING_SECOND_TRAIN_CARD].include?(turn_status)
      return
    end

    case phase
    when PHASE_INITIAL
      if last_player_in_loop?
        self.phase = PHASE_PLAY
        self.turn_status = TURN_STATUS_PLAYING
      else
        self.turn_status = TURN_STATUS_WAITING_TO_DISCARD
      end
      self.turn_player = next_player
    when PHASE_PLAY
      check_for_final_round!
      self.turn_player = next_player
    when PHASE_LAST_ROUND
      if last_player.id == turn_player.id
        self.phase = PHASE_END
      else
        self.turn_player = next_player
      end
    else
      raise "Unknown phase #{phase}"
    end
  end

  def building_allowed?(user)
    [ PHASE_PLAY, PHASE_LAST_ROUND ].include?(phase) && turn_status == TURN_STATUS_PLAYING && users_turn?(user)
  end

  def destination_ticket_drawable?(user)
    users_turn?(user) && [ PHASE_PLAY, PHASE_LAST_ROUND ].include?(phase) && turn_status == TURN_STATUS_PLAYING
  end

  def end_phase?
    phase == PHASE_END
  end

  def joinable?(user)
    phase == PHASE_SETUP && !is_player?(user)
  end

  def is_player?(user)
    players.where(user_id: user.id).count > 0
  end

  def over?
    phase == PHASE_END
  end

  def setup_phase?
    phase == PHASE_SETUP
  end

  def started?
    phase != PHASE_SETUP
  end

  def startable?(user)
    phase == PHASE_SETUP && is_player?(user)
  end

  def train_card_drawable?(user)
    [ PHASE_PLAY, PHASE_LAST_ROUND ].include?(phase) && [ TURN_STATUS_PLAYING, TURN_STATUS_DRAWING_SECOND_TRAIN_CARD ].include?(turn_status) && users_turn?(user)
  end

  def users_turn?(user)
    turn_player && turn_player.user_id == user.id
  end

  def waiting_for_players_turn?(user)
    !users_turn?(user) && started? && !over?
  end

  def waiting_to_discard_destination_tickets?(user)
    [ PHASE_INITIAL, PHASE_PLAY, PHASE_LAST_ROUND ].include?(phase) && turn_status == TURN_STATUS_WAITING_TO_DISCARD && users_turn?(user)
  end

  private

  def next_player
    if last_player_in_loop?
      players.position_order.limit(1).take!
    else
      players.where(position: turn_player.position + 1).take!
    end
  end

  def check_for_final_round!
    if turn_player.train_cars <= TRAIN_COUNT_GAME_END_THRESHOLD
      self.last_player = turn_player
      self.phase = PHASE_LAST_ROUND
    end
  end

  def last_player_in_loop?
    players.count == (turn_player.position + 1)
  end
end
