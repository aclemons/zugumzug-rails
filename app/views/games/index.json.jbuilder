json.array! @games, partial: 'games/game', as: :game, locals: { current_user: @current_user }
