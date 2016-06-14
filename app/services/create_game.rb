class CreateGame < AbstractService
  include SortHelper

  DESTINATION_TICKET_DEAL_SIZE = 3
  TRAIN_CARD_DEAL_SIZE = 4

  def initialize
    super(nil, nil)
  end

  def call
    update_game do
      self.game = Game.new({ phase: Game::PHASE_SETUP, turn_status: Game::TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN })

      save_object(game)

      initialise_routes

      initialise_destination_tickets

      initialise_train_cards

      true
    end
  end

  private

  def initialise_routes
    Route.all.each do |route|
      game_route = game.game_routes.new({ game: @game, route: route })

      save_object(game_route)
    end
  end

  def initialise_destination_tickets
    destinations = random_sort DestinationTicket.all.to_a

    destinations.each_with_index do |d,i|
      game_destination = game.game_destination_tickets.new({
        game: game,
        destination_ticket: d,
        deck_position: i,
        status: GameDestinationTicket::STATE_UNASSIGNED
      })
      save_object(game_destination)
    end
  end

  def initialise_train_cards
    cards = random_sort TrainCard.all.to_a

    cards.each_with_index do |c,i|
      game_train_card = game.game_train_cards.new({
        game: game,
        train_card: c,
        deck_position: i,
        status: GameTrainCard::STATE_UNASSIGNED
      })
      save_object(game_train_card)
    end
  end
end
