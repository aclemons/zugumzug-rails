class DrawDestinationTickets < AbstractService
  include SortHelper

  DRAW_COUNT = 3

  def call
    @drawn_destinations = []

    update_game do
      until drawn_destinations.count == DRAW_COUNT do
        remaining_draw_count = DRAW_COUNT - drawn_destinations.count

        available = game.game_destination_tickets.next_deck_tickets(remaining_draw_count)

        if available.empty?
          sorted_tickets = sort_discarded

          if sorted_tickets.empty?
            break
          end

          game.game_destination_tickets.reload
          next
        end

        assign_destinations_to_player(available, player)

        drawn_destinations.concat(available)
      end

      if drawn_destinations.empty?
        errors.add(:base, :no_destination_tickets_available)
        next false
      end

      game.turn_status = Game::TURN_STATUS_WAITING_TO_DISCARD
      game.update_game_status!
      save_object(game)

      true
    end
  end

  def allowed_phases
    [ Game::PHASE_INITIAL, Game::PHASE_PLAY, Game::PHASE_LAST_ROUND ]
  end

  def allowed_turn_states
    [ Game::TURN_STATUS_PLAYING ]
  end

  private

  attr_reader :drawn_destinations

  def sort_discarded
    discarded = game.game_destination_tickets.with_status(GameDestinationTicket::STATE_DISCARDED).to_a

    return discarded if discarded.empty?

    random_sort!(discarded)

    discarded.each_with_index do |destination, i|
      destination.shuffle_to_position!(i)
      save_object(destination)
    end

    discarded
  end

  def assign_destinations_to_player(destinations, player)
    destinations.each do |destination|
      destination.deal_to_player!(player)
      save_object(destination)
    end
  end
end
