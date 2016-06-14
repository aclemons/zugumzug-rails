json.id                 game.id
json.phase              game.phase
json.phase_name         Game.phase_name(game.phase)
json.turn_status        game.turn_status
json.turn_status_name   Game.turn_status_name(game.turn_status)

unless game.turn_player.nil?
  json.turn_player        game.turn_player.id
  json.turn_user_id        game.turn_player.user.id
  json.turn_player_colour Colour.name(game.turn_player.colour)
end

unless game.last_player.nil?
  json.last_player        game.last_player.id
  json.last_player_colour Colour.name(game.last_player.colour)
end

unless game.winner.nil?
  json.winner        game.last_player.id
  json.winner_colour Colour.name(game.last_player.colour)
end

json.players do
  json.array!(game.players.position_order.map do |p|
    {
      player_id: p.id,
      name: p.name,
      user_id: p.user.id,
      position: p.position,
      points: p.points,
      colour: p.colour,
      colour_name: Colour.name(p.colour),
      longest_continuous_path: p.longest_continuous_path,
      train_cars: p.train_cars,

      train_cards: p.game_train_cards.map do |c|
        if p.user_id == current_user.id || game.phase == Game::PHASE_END
          {
            card_id: c.train_card.id,
            colour: c.train_card.colour,
            colour_name: Colour.name(c.train_card.colour, true)
          }
        else
          nil
        end
      end.compact,
      destination_tickets: p.game_destination_tickets.map do |d|
        if p.user_id == current_user.id || game.phase == Game::PHASE_END
          {
            ticket_id: d.destination_ticket.id,
            status: d.status,
            status_name: GameDestinationTicket.status_name(d.status),
            from: d.destination_ticket.from.id,
            from_name: d.destination_ticket.from.name,
            to: d.destination_ticket.to.id,
            to_name: d.destination_ticket.to.name,
            points: d.destination_ticket.points,
            completed: d.completed
          }
        else
          nil
        end
      end.compact
    }
  end)
end

json.train_cards do
  json.array!(game.game_train_cards.where(status: GameTrainCard::STATE_FACE_UP).map do |c|
    {
      card_id: c.train_card.id,
      colour: c.train_card.colour,
      colour_name: Colour.name(c.train_card.colour, true)
    }
  end)
end

json.routes do
  json.array!(game.game_routes.id_order.map do |r|
    {
      route_id: r.route.id,
      player_id: r.player.nil? ? nil : r.player.id,
      player_colour: r.player.nil? ? nil : r.player.colour,
      player_name: r.player.nil? ? nil : r.player.name,
      from: r.route.from.id,
      from_name: r.route.from.name,
      from_latitude: r.route.from.latitude,
      from_longitude: r.route.from.longitude,
      to: r.route.to.id,
      to_name: r.route.to.name,
      to_latitude: r.route.to.latitude,
      to_longitude: r.route.to.longitude,
      colour: r.route.colour,
      colour_name: Colour.name(r.route.colour),
      length: r.route.length
    }
  end)
end
