class AddPlayer < AbstractService
  def call
    update_game do
      add_player

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

  def add_player
    player.train_cars = Player::TRAINS_PER_PLAYER
    player.position = game.players.count
    player.points = 0
    player.longest_continuous_path = false
    save_object(player)
  end
end
