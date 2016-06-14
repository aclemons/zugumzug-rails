class Ability
  include CanCan::Ability

  def initialize(user)
    if user
      can [ :index, :show, :update ], User, :id => user.id

      can [ :create, :new ], Game
      can :update, Game do |game|
        game.phase == Game::PHASE_SETUP && game.players.for_user(user.id).first
      end
      can :show, Game do |game|
        game.phase == Game::PHASE_SETUP || game.players.for_user(user.id).first
      end
      can :index, Game, Game.for_user(user.id) do
      end

      can :index,  User, :id => user.id

      can [ :create, :discard_destination_tickets, :draw_destination_tickets, :draw_train_card, :build_route ], Player do |player|
        player.user_id == user.id
      end
    end

    can :index, City
    can :show, City
  end
end
