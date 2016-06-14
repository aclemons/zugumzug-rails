class BuildRoute < AbstractService

  def initialize(game, player, route_id, train_card_ids)
    super(game, player)
    @route_id = route_id
    @train_card_ids = train_card_ids
  end

  def call
    update_game do
      next false unless verify_route

      unless player.train_cars >= route.route.length
        parameters = {
          route_id: route.route.id,
          train_cars: player.train_cars,
          route_length: route.route.length,
          from: route.route.from.name,
          to: route.route.to.name
        }

        errors.add(:base, :not_enough_train_cars_for_route, parameters)

        next false
      end

      player_cards = collect_player_cards

      next false unless cards_match_route?(route, player_cards)

      player.train_cars -= route.route.length
      player.points += route.route.points

      save_object(player)

      player_cards.each do |card|
	card.play!

        save_object(card)
      end

      route.player = player

      save_object(route)

      game.turn_player.reload

      game.turn_status = Game::TURN_STATUS_PLAYING
      game.update_game_status!

      save_object(game)

      EndGame.new().check_for_completed_routes(game, player, save_object_callback)

      true
    end
  end

  def allowed_phases
    [ Game::PHASE_PLAY, Game::PHASE_LAST_ROUND ]
  end

  def allowed_turn_states
    [ Game::TURN_STATUS_PLAYING ]
  end

  private

  attr_reader :train_card_ids, :route_id, :route

  def collect_player_cards
    if train_card_ids.nil? || train_card_ids.empty?
      choose_cards_for_route(player, route)
    else
      find_train_cards(player, route)
    end
  end


  def verify_route
    game_route = game.game_routes.for_route(route_id).first

    unless game_route
      errors.add(:base, :unknown_route, { route_id: route_id })
      return nil
    end

    unless game_route.player.nil?
      parameters = {
        route_id: route_id,
        player_id: game_route.player.id,
        player_name: game_route.player.name,
        from: game_route.route.from.name,
        to: game_route.route.to.name
      }

      errors.add(:base, :route_already_built, parameters)

      return nil
    end

    if game.players.count <= 3
      parallel_route = parallel_routes(game_route).find { |parallel_route| parallel_route.player }

      if parallel_route
        parameters = {
          route_id: route_id,
          player_id: parallel_route.player.id,
          player_name: parallel_route.player.name,
          from: game_route.route.from.name,
          to: game_route.route.to.name
        }

        errors.add(:base, :parallel_route_not_allowed_for_game, parameters)

        return nil
      end
    else
      parallel_route = parallel_routes(game_route).find { |parallel_route| parallel_route.player.id == player_id }

      if parallel_route
        parameters = {
          route_id: route_id,
          player_id: parallel_route.player.id,
          player_name: parallel_route.player.name,
          from: game_route.route.from.name,
          to: game_route.route.to.name
        }

        errors.add(:base, :parallel_route_not_allowed_for_same_player, parameters)

        return nil
      end
    end

    @route = game_route
  end

  def parallel_routes(game_route)
    game.game_routes.parallel_to(game_route)
  end

  def find_train_cards(player, game_route)
    selected_cards = player.game_train_cards.where(train_card_id: train_card_ids)

    unless selected_cards.count == game_route.route.length
      add_mismatch_card_selection_error(selected_cards, game_route)
      raise ActiveRecord::Rollback
    end

    selected_cards
  end

  def choose_cards_for_route(player, game_route)
    if game_route.route.colour == Colour::NONE
      grouped_cards = player.game_train_cards.group_by { |card| card.train_card.colour }

      selected_locomotive_cards = grouped_cards[ Colour::NONE ] || []

      grouped_cards.delete(Colour::NONE)

      colour_cards_tuple = grouped_cards.max_by{ |colour, cards| cards.count }
      selected_cards = colour_cards_tuple[1].take(game_route.route.length)

      if selected_cards.count < game_route.route.length
        selected_cards.concat(selected_locomotive_cards.take(game_route.route.length - selected_cards.count))
      end
    else
      selected_cards = player.game_train_cards.of_colour(game_route.route.colour).limit(game_route.route.length).to_a

      if selected_cards.count < game_route.route.length
        selected_locomotive_cards = player.game_train_cards.locomotives.limit(game_route.route.length - selected_cards.count)

        selected_cards.concat(selected_locomotive_cards)
      end
    end

    unless selected_cards.count == game_route.route.length
      add_mismatch_card_selection_error(selected_cards, game_route)
      raise ActiveRecord::Rollback
    end

    selected_cards
  end

  def cards_match_route?(game_route, player_cards)
    coloured_cards = player_cards.reject { |card| card.train_card.locomotive? }

    unless coloured_cards.group_by { |card| card.train_card.colour }.size <= 1
      errors.add(:base, :set_of_train_cards_for_route_must_have_matching_colour, { route_id: route_id })
      raise ActiveRecord::Rollback
    end

    # route is grey - any set of matching cards matches route
    return true if game_route.route.grey?

    # cards must match route colour
    return true if coloured_cards.all? { |card| card.train_card.colour == game_route.route.colour }

    errors.add(:base, :set_of_train_cards_for_route_must_have_route_colour, { route_id: route_id })
    raise ActiveRecord::Rollback
  end

  def add_mismatch_card_selection_error(selected_cards, game_route)
    parameters = {
      route_id: route_id,
      selected_count: selected_cards.count,
      route_length: game_route.route.length,
      from: game_route.route.from.name,
      to: game_route.route.to.name,
    }
    errors.add(:base, :invalid_set_of_train_cards_for_route, parameters)
  end
end
