module GamePolicy
  def enforce_game_policy(game, player, policy, action)
    if game
      unless policy.allowed_phases.include?(game.phase)
        action.errors.add(:base, :operation_not_allowed_in_phase, { operation: action.operation, phase: game.phase })
        return nil
      end

      unless policy.allowed_turn_states.include?(game.turn_status)
        action.errors.add(:base, :operation_not_allowed_in_turn_status, { operation: action.operation, turn_status: game.turn_status })
        return nil
      end
    end

    if player && !player.new_record?
      unless game.turn_player.id == player.id
        errors.add(:base, :not_players_turn, { turn_player_id: game.turn_player.id })
        return nil
      end
    end

    true
  end
end
