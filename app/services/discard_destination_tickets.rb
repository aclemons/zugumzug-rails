class DiscardDestinationTickets < AbstractService
  REQUIRED_CARDS_TO_KEEP_INITIAL = 2
  REQUIRED_CARDS_TO_KEEP_DURING_PLAY = 1

  def initialize(game, player, destination_ids)
    super(game, player)
    @destination_ids = destination_ids
  end

  def call
    update_game do
      next update_game_status(player) if destination_ids.empty?

      unless destination_ids.count <= max_discardable_card_count
        errors.add(:base, :invalid_destination_discard_count, { discard_count: destination_ids.count, max_discard_count: max_discardable_card_count })
        next false
      end

      destination_ids.each do |id|
        discard_ticket(player, id)
      end

      unless update_game_status(player)
        raise ActiveRecord::Rollback
      end

      true
    end
  end

  def allowed_phases
    [ Game::PHASE_INITIAL, Game::PHASE_PLAY, Game::PHASE_LAST_ROUND ]
  end

  def allowed_turn_states
    [ Game::TURN_STATUS_WAITING_TO_DISCARD ]
  end

  private

  attr_reader :destination_ids

  def max_discardable_card_count
    (DrawDestinationTickets::DRAW_COUNT - required_cards_to_keep)
  end

  def required_cards_to_keep
    game.phase == Game::PHASE_INITIAL ? REQUIRED_CARDS_TO_KEEP_INITIAL : REQUIRED_CARDS_TO_KEEP_DURING_PLAY
  end

  def discard_ticket(player, id)
    game_destination_ticket = player.game_destination_tickets.for_destination_ticket(id).first

    unless game_destination_ticket
      errors.add(:base, :player_not_not_have_destination_ticket, { ticket_id: id })
      raise ActiveRecord::Rollback
    end

    unless game_destination_ticket.pending?
      errors.add(:base, :destination_ticket_in_wrong_status_for_discard, { expected_status: GameDestinationTicket::STATE_PENDING, status: game_destination_ticket.status })
      raise ActiveRecord::Rollback
    end

    game_destination_ticket.discard!

    save_object game_destination_ticket
  end

  def update_game_status(player)
    keep_remaining_destination_tickets(player)

    game.turn_status = Game::TURN_STATUS_PLAYING
    game.update_game_status!

    save_object game

    true
  end

  def keep_remaining_destination_tickets(player)
    player.game_destination_tickets.with_pending_status.each do |ticket|
      ticket.assign!
      save_object ticket
    end
  end
end
