class Player < ActiveRecord::Base
  TRAINS_PER_PLAYER = 45

  def self.allowed_player_colours_for_game(game)
    Colour::player_colours - game.players.map { |player| player.colour }
  end

  before_validation { self.name = user.name unless name || user.nil? }

  validates :user_id, presence: true, uniqueness: { scope: [:game_id] }

  validates :name, presence: true, length: { minimum: 3, maximum: 50 },
                   uniqueness: { scope: [:game_id] }

  validates_inclusion_of :colour, :in => Colour::player_colours
  validates :colour, uniqueness: { scope: [:game_id] }
  validates :train_cars, numericality: { only_integer: true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => TRAINS_PER_PLAYER }

  belongs_to :game
  belongs_to :user

  has_many :game_destination_tickets
  has_many :destination_tickets, through: :game_destination_tickets

  has_many :game_train_cards
  has_many :train_cards, through: :game_train_cards

  has_many :game_routes
  has_many :routes, through: :game_routes

  scope :position_order, -> { order(position: :asc) }
  scope :first_player, -> { position_order.limit(1) }
  scope :for_user, -> (user_id) { where(user_id: user_id).limit(1) }
  scope :of_colour, -> (colour) { where(colour: colour).limit(1) }
  scope :other_players, -> (user_id) { where.not('players.user_id = ?', user_id) }
end

