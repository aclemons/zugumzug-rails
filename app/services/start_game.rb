class StartGame < AbstractService
  DESTINATION_TICKET_DEAL_SIZE = 3
  TRAIN_CARD_DEAL_SIZE = 4

  def initialize(game)
    super(game, nil)
  end

  def call
    update_game do
      unless game.players.count.between?(Game::MIN_PLAYERS, Game::MAX_PLAYERS)
        errors.add(:base, :incorrect_player_count_for_game, { min_players: Game::MIN_PLAYERS, max_players: Game::MAX_PLAYERS, player_count: game.players.count })
        next false
      end

      game.phase = Game::PHASE_INITIAL
      game.turn_status = Game::TURN_STATUS_WAITING_TO_DISCARD
      game.turn_player = game.players.first_player.first

      save_object(game)

      deal_destination_tickets

      deal_player_train_cards

      deal_visible_train_cards

      true
    end
  end

  def allowed_phases
    [ Game::PHASE_SETUP ]
  end

  def allowed_turn_states
    [ Game::TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN ]
  end

  private

  def deal_destination_tickets
    DESTINATION_TICKET_DEAL_SIZE.times.each { deal_destination_ticket_to_players }
  end

  def deal_destination_ticket_to_players
    game.players.position_order.each do |player|
      ticket = game.game_destination_tickets.next_deck_ticket.first!

      ticket.deal_to_player!(player)

      save_object(ticket)
    end
  end

  def deal_player_train_cards
    TRAIN_CARD_DEAL_SIZE.times.each { deal_train_card_to_each_player }
  end

  def deal_train_card_to_each_player
    game.players.position_order.each { |player| deal_train_card_to_player(player) }
  end

  def deal_train_card_to_player(player)
    train_card = draw_next_train_card

    train_card.deal_to_player!(player)

    save_object(train_card)
  end

  def deal_visible_train_cards
    visible = []
    until visible.count == Game::VISIBLE_TRAIN_CARD_COUNT
      card = draw_next_train_card
      card.turn_over!

      save_object(card)

      visible << card

      if locomotive_count(visible) > Game::MAX_VISIBLE_LOCOMOTIVES
        discard_train_cards(visible)
        visible.clear
      end
    end
  end

  def locomotive_count(cards)
    cards.count { |card| card.train_card.locomotive? }
  end

  def draw_next_train_card
    game.game_train_cards.next_deck_card.first!
  end

  def discard_train_cards(cards)
    cards.each do |played_card|
      played_card.play!
      save_object(played_card)
    end
  end
end
