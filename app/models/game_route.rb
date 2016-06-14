class GameRoute < ActiveRecord::Base
  belongs_to :game
  belongs_to :route
  belongs_to :player

  scope :id_order, -> { order(route_id: :asc) }
  scope :touching, -> (city) { joins(:route).where('routes.from_id = ? OR routes.to_id = ?', city, city) }
  scope :for_route, -> (route_id) { where(route_id: route_id).limit(1) }
  scope :parallel_to, -> (game_route) {
    joins(:route)
    .where.not(route_id: game_route.route_id)
    .where('((routes.from_id = ? and routes.to_id = ?) or (routes.from_id = ? and routes.to_id = ?))',
           game_route.route.to_id, game_route.route.from_id, game_route.route.from_id, game_route.route.to_id)
  }
  scope :available, -> { where(player_id: nil) }
end
