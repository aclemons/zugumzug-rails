require 'set'

# TODO: errors
# save_callback => on_success
class EndGame
  # TODO Constructor
  def check_for_completed_routes(game, player, save_callback)
    longest_routes = {}

    paths = get_all_paths_for_all_cities(player)

    player_paths_as_city_list = paths.map do |path|
      path.map { |edge| [ edge.from, edge.to ] }.flatten(1).chunk{ |n| n }.map(&:first)
    end

    destination_ticket_points = player.game_destination_tickets.each do |game_ticket|
      game_ticket.completed = completed?(game_ticket, player_paths_as_city_list)
      do_save_object(game_ticket, save_callback)
    end
  end

  def check_for_end_of_game(game, save_callback)
    unless game.phase == Game::PHASE_END
      return
    end

    longest_routes = game.players.each_with_object({}) do |player, longest_routes|
      points = calculate_points_for_destination_tickets(player)

      player.points += points
      do_save_object(player, save_callback)

      paths = get_all_paths_for_all_cities(player)

      longest_routes[player] = length_of_longest_route(player, paths)
    end

    handle_longest_route(longest_routes, save_callback)

    calculate_winner(game, save_callback)
  end

  private

  class Edge < Struct.new(:from, :to, :length)
  end

  def completed?(game_ticket, player_paths_as_city_list)
    player_paths_as_city_list.any? { |cities| cities.include?(game_ticket.destination_ticket.from.id) && cities.include?(game_ticket.destination_ticket.to.id) }
  end

  def do_save_object(object, save_callback)
    save_callback.call(object)
  end

  def calculate_points_for_destination_tickets(player)
    destination_ticket_points = player.game_destination_tickets.reduce(0) do |sum, game_ticket|
      if game_ticket.completed
        1
      else
        -1
      end * game_ticket.destination_ticket.points + sum
    end
  end

  def length_of_longest_route(player, paths)
    paths.map { |edges| edges.reduce(0) { |sum, edge| sum + edge.length } }.max || 0
  end

  def get_all_paths_for_all_cities(player)
    cities = player.routes.reduce(Set.new) do |cities, route|
      cities.add(route.to_id)
      cities.add(route.from_id)

      cities
    end

    cities.map do |city|
      paths = []

      build_all_paths_from_city(player, nil, city, paths, Hash.new(false), [])

      paths
    end.flatten(1)
  end

  def build_all_paths_from_city(player, previous_city, city, paths, visited, current_path)
    unless previous_city.nil?
      route = Route.where('(from_id = ? and to_id = ?) or (from_id = ? and to_id = ?)', previous_city, city, city, previous_city).limit(1).take!

      current_path << Edge.new(previous_city, city, route.length)
    end

    cities = find_adjacent_unvisited_cities(player, city, visited)

    if cities.empty?
      paths.push(current_path)

      return
    end

    cities.each do |next_city|
      next_visited = visited.dup
      next_visited[ [ city, next_city ] ] = true

      next_current_path = current_path.dup

      build_all_paths_from_city(player, city, next_city, paths, next_visited, next_current_path)
    end
  end

  def find_adjacent_unvisited_cities(player, city, visited)
    adjacent_cities = player.game_routes.touching(city).reduce([]) do |cities, game_route|
      from = game_route.route.from_id
      to = game_route.route.to_id

      cities << from unless city == from || cities.include?(from)
      cities << to unless city == to || cities.include?(to)

      cities
    end

    adjacent_cities.reject do |next_city|
      edge = [city, next_city]

      visited.has_key?(edge) || visited.has_key?(edge.reverse)
    end
  end

  def handle_longest_route(longest_routes, save_callback)
    max_length = longest_routes.values.max

    longest_routes.each do |player, route_length|
      next unless route_length == max_length

      player.points += 10
      player.longest_continuous_path = true

      do_save_object(player, save_callback)
    end
  end

  def calculate_winner(game, save_callback)
    max_points = game.players.map { |player| player.points }.max

    max_point_players = game.players.to_a.select { |player| player.points == max_points }

    if max_point_players.count == 1
      game.winner = max_point_players.first
    else
      longest_path_players = max_point_players.find_all { |player| player.longest_path_card }

      raise "The rules of the game do not handle this case" if longest_path_players.count != 1

      game.players = longest_path_players.first
    end

    do_save_object(game, save_callback)
  end
end
