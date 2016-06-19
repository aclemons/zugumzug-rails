require 'gnuplot'

class GamePresenter
  def initialize(game, current_user)
    @game = game
    @current_user = current_user
  end

  def render_map
    arrow_set_stmts = []
    hash_of_edges = collect_edges(arrow_set_stmts)

    user_cities = if game.over?
      game.players.map do |player|
        player.destination_tickets.map { |dt| [ dt.from.name, dt.to.name ] }.flatten
      end
    else
      game.players.for_user(current_user.id).first.destination_tickets.map { |dt| [ dt.from.name, dt.to.name ] }
    end.flatten

    all_cities = City.all

    cities = all_cities.reduce([ [], [], [] ]) do |input, city|
      input[0] << city.longitude.to_f
      input[1] << city.latitude.to_f
      input[2] << "\"#{city.name}\""

      input
    end

    non_player_city_data = all_cities.reduce([ [], [], [] ]) do |input, city|
      if !user_cities.include?(city.name)
        input[0] << city.longitude.to_f
        input[1] << city.latitude.to_f
        input[2] << "\"#{city.name}\""
      end

      input
    end

    plot_id_to_edge_mapping = {}

    xml = Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.set "encoding utf8"
        plot.set "term svg dynamic enhanced font 'Verdana,6'"

        plot.unset "border"
        plot.unset "xtics"
        plot.unset "ytics"
        plot.unset "colorbox"

        plot.set "noclip points"
        plot.set "noclip one"
        plot.set "noclip two"

        arrow_set_stmts.each do |arrow_stmt|
          plot.set arrow_stmt
        end

        plot_id = 1
        hash_of_edges.each do |colour, array|
          array.each do |edge|
            data = %w[ x y x_diff y_diff arrow_style ].map { |msg| [ edge.public_send(msg) ] }

            plot.data << Gnuplot::DataSet.new( data ) do |ds|
              ds.using = "1:2:3:4:5"
              ds.with = "vectors arrowstyle variable"
              ds.notitle
            end

            if edge.route_id
              plot_id_to_edge_mapping[plot_id] = edge
            end

            plot_id += 1
          end
        end

        plot.data << Gnuplot::DataSet.new( non_player_city_data ) do |ds|
          ds.using = "1:2:3"
          ds.with = "labels center offset 1,1 point pt 20 ps 0.5"
          ds.notitle
        end

        if game.over?
          game.players.map do |player|
            next if player.user_id == current_user.id
            plot_labels_for_player(player, plot)
          end
        end

        # plot the logged in user last
        plot_labels_for_player(game.players.for_user(current_user.id).first, plot)
      end
    end

    enrich_svg(xml, plot_id_to_edge_mapping)
  end

  private

  attr_reader :game, :current_user

  def enrich_svg(xml, plot_id_to_edge_mapping)
    xmldoc = Nokogiri.XML(xml)

    plot_id_to_edge_mapping.each do |plot_id, edge|
      game_route = edge.game_route
      route_id = game_route.route_id
      node = xmldoc.xpath("//*[local-name()='g' and @id='gnuplot_plot_#{plot_id}']//*[local-name()='path']")[0]
      node['class'] = "route"
      node['id'] = "route-#{route_id}"
      node['onmousemove'] = "ShowTooltip(evt, 'Route ##{route_id} - #{game_route.route.from.name} <=> #{game_route.route.to.name}')"
      node['onmouseout'] = "HideTooltip(evt)"
      node['onclick'] = "SelectRoute(evt, '#{route_id}')"


      unless game_route.player
        route_length = game_route.route.length

        x, y, x2, y2 = node['d'].match(/^M(.*),(.*)\s+L(.*),(.*)\s*$/).captures
        xdiff = x2.to_f - x.to_f
        ydiff = y2.to_f - y .to_f

        vector_length = Math.sqrt((xdiff * xdiff) + (ydiff * ydiff))

        node['stroke-dasharray'] = "#{vector_length / (2.0 * route_length)}"

        if route_length % 2 == 0
          node['stroke-dashoffset'] = "#{1.25 * (vector_length / (2.0 * route_length))}"
        else
          node['stroke-dashoffset'] = "#{1.5 * (vector_length / (2.0 * route_length))}"
        end
      end
    end

    plot_id_to_edge_mapping.each do |plot_id, edge|
      game_route = edge.game_route
      route_id = game_route.route_id
      node = xmldoc.xpath("//*[local-name()='g' and @id='gnuplot_plot_#{plot_id}']//*[local-name()='title']")[0]
      node.content = "route-#{route_id} - #{I18n.t(:ROUTE_LENGTH)} #{game_route.route.length}"
    end

    script = Nokogiri::XML::Node.new("script", xmldoc)
    script['type'] = "text/ecmascript"
    script.content =%{
      function init(evt)
      {
        if ( window.svgDocument == null )
        {
          svgDocument = evt.target.ownerDocument;
        }

        tooltip = svgDocument.getElementById('tooltip');
        tooltip_bg = svgDocument.getElementById('tooltip_bg');
        select_list = document.getElementById('route_id');
      }

      function ShowTooltip(evt, mouseovertext)
      {
        tooltip.setAttributeNS(null, "x", evt.clientX + 11);
        tooltip.setAttributeNS(null, "y", evt.clientY + 27);
        tooltip.firstChild.data = mouseovertext;
        tooltip.setAttributeNS(null, "visibility", "visible");

        length = tooltip.getComputedTextLength();
        tooltip_bg.setAttributeNS(null, "width", length + 8);
        tooltip_bg.setAttributeNS(null, "x", evt.clientX + 8);
        tooltip_bg.setAttributeNS(null, "y", evt.clientY + 14);
        tooltip_bg.setAttributeNS(null, "visibility", "visible");
      }

      function HideTooltip(evt)
      {
        tooltip.setAttributeNS(null, "visibility", "hidden");
        tooltip_bg.setAttributeNS(null, "visibility", "hidden");
      }

      function SelectRoute(evt, route_id)
      {
        for (var i = 0; i < select_list.options.length; i++)
        {
          if (select_list.options[i].value === route_id)
          {
            select_list.options[i].selected = true;
            return;
          }
        }
      }
    }
    xmldoc.root.prepend_child(script)

    style = Nokogiri::XML::Node.new("style", xmldoc)
    style.content =%{
      .tooltip_bg{
        fill: white;
        stroke: black;
        stroke-width: 1;
        opacity: 0.85;
      }
      path {
        pointer-events: all;
      }
    }
    xmldoc.root.prepend_child(style)

    tooltip_bg = Nokogiri::XML::Node.new("rect", xmldoc)
    tooltip_bg['id']="tooltip_bg"
    tooltip_bg['class']="tooltip_bg"
    tooltip_bg['x']="0"
    tooltip_bg['y']="0"
    tooltip_bg['rx']="4"
    tooltip_bg['ry']="4"
    tooltip_bg['width']="55"
    tooltip_bg['height']="17"
    tooltip_bg['visibility']="hidden"
    xmldoc.root.add_child(tooltip_bg)

    tooltip = Nokogiri::XML::Node.new("text", xmldoc)
    tooltip['id']="tooltip"
    tooltip['class']="tooltip"
    tooltip['x']="0"
    tooltip['y']="0"
    tooltip['visibility']="hidden"
    tooltip.content = "Tooltip"
    xmldoc.root.add_child(tooltip)

    xmldoc.root['onload'] = "init(evt)"

    xml = xmldoc.to_s
  end

  def plot_labels_for_player(player, plot)
    user_cities = player.destination_tickets.map { |dt| [dt.from.name, dt.to.name] }.flatten

    player_city_data = City.all.reduce([[], [], [] ]) do |input, city|
      if user_cities.include?(city.name)
        input[0] << city.longitude.to_f
        input[1] << city.latitude.to_f
        input[2] << "\"#{city.name}\""
      end

      input
    end

    colour_name = Colour::html_name(player.colour)

    plot.data << Gnuplot::DataSet.new( player_city_data ) do |ds|
      ds.using = "1:2:3"
      ds.with = "labels center offset 1,1 point pt 20 ps 0.5 lc rgb \"#{colour_name}\""
      ds.notitle
    end
  end

  def collect_edges(arrow_set_stmts)
    arrow_style = 1

    # group by parallel routes
    grouped_routes = game.game_routes.group_by { |game_route| [ game_route.route.from.id, game_route.route.to_id ].sort }

    edges_by_colour = {}

    grouped_routes.each do |key, game_route_array|
      offsets = case game_route_array.count
      when 1
        [ 0 ]
      when 2
        [ 0.2, -0.2 ]
      else
        raise 'Unsupported game configuration. There should never be more than two parallel routes'
      end

      game_route_array.zip(offsets).each do |game_route, multiplier|
        colour = if game_route.player
          game_route.player.colour
        else
          game_route.route.colour
        end

        add_edge_for_route(game_route, edges_by_colour, multiplier, colour, arrow_style, arrow_set_stmts)

        arrow_style += 1
      end
    end

    edges_by_colour
  end

  def add_edge_for_route(game_route, edges_by_colour, multiplier, colour, arrow_style, arrow_set_stmts)
    route = game_route.route
    route_id = route.id
    route_length = route.length

    input = edges_by_colour[colour]
    unless input
      input = []
      edges_by_colour[colour] = input
    end

    # use off-white since we have a white background
    colour_name = colour == Colour::WHITE ? "#FDF5E6" : Colour::name(colour)

    from = [ route.from.longitude.to_f, route.from.latitude.to_f ]
    to = [ route.to.longitude.to_f, route.to.latitude.to_f ]

    angle = angle(from, to)

    x_offset, y_offset = calculate_vector_shift(multiplier, angle.abs)

    adjusted_from_x = route.from.longitude.to_f + x_offset
    adjusted_from_y = route.from.latitude.to_f + x_offset

    adjusted_to_x = route.to.longitude.to_f + x_offset
    adjusted_to_y = route.to.latitude.to_f + x_offset

    adjusted_x_diff = adjusted_to_x - adjusted_from_x
    adjusted_y_diff = adjusted_to_y - adjusted_from_y

    if game_route.player
      arrow_set_stmts << "style line #{arrow_style} lc rgb \"#{colour_name}\" lw 2"
    else
      arrow_set_stmts << "style line #{arrow_style} lc rgb \"#{colour_name}\" lw 4 dt 2"
    end

    arrow_set_stmts << "style arrow #{arrow_style} nohead ls #{arrow_style} lc rgb \"#{colour_name}\""

    input << Edge.new( adjusted_from_x, adjusted_from_y, adjusted_x_diff, adjusted_y_diff, arrow_style, route_id, game_route )
  end

  def angle(a, b)
    latitude_diff = b[1] - a[1]
    longitude_diff = b[0] - a[0]

    Math.atan2(latitude_diff, longitude_diff) * 180 / Math::PI
  end

  def calculate_vector_shift(multiplier, angle)
    if angle.ceil == 90
      [ multiplier, 0 ]
    elsif angle.floor == 0
      [ 0, multiplier ]
    else
      [ (angle / 90.0) * multiplier, ((90 - angle) / 90.0) * multiplier ]
    end
  end

  class Edge < Struct.new(:x, :y, :x_diff, :y_diff, :arrow_style, :route_id, :game_route)
  end
end
