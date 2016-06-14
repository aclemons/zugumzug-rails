require 'rails_helper'

RSpec.describe BuildRoute do
  let(:destination_ids) { [] }
  let(:game_id) do
    Game.all.last.id
  end
  let(:game) { Game.find(game_id) }
  let(:train_card_ids) { nil }
  let(:route_id) { Game.find(game_id).routes.find { |r| r.from.name == 'New York City' && r.to.name == 'Boston' }.id }
  let(:parallel_route_id) { Game.find(game_id).routes.find { |r| r.from.name == 'New York City' && r.to.name == 'Boston' && r.id != route_id }.id }
  let(:route_length) { Route.find_by_id(route_id).length }
  let(:route_points) { Route.find_by_id(route_id).points }
  let(:initial_train_cars) { 45 }
  let(:coloured_take_count) { 2 }
  let(:locomotive_take_count) { 2 }
  let(:matching_coloured_train_cards) do
    local_route = Route.find_by_id(route_id)
    if local_route
      if local_route.grey?
        Game.find(game_id).game_train_cards.unassigned.of_colour(Colour::RED).limit(coloured_take_count).map { |c| c.train_card.id }
      else
        Game.find(game_id).game_train_cards.unassigned.of_colour(local_route.colour).limit(coloured_take_count).map { |c| c.train_card.id }
      end
    else
      []
    end
  end
  let(:nonmatching_coloured_train_cards) do
    local_route = Route.find_by_id(route_id)
    if local_route
      Game.find(game_id).game_train_cards.unassigned.of_colour(Colour::BLACK).limit(coloured_take_count).map { |c| c.train_card.id }
    else
      []
    end
  end
  let(:matching_locomotive_train_cards) do
    Game.find(game_id).game_train_cards.unassigned.of_colour(Colour::NONE).limit(locomotive_take_count).map { |c| c.train_card.id }
  end
  let(:route_owner) { nil }
  let(:parallel_route_owner) { nil }

  shared_examples_for "a successful service" do
    it "is a success" do
      expect(@result).to be_truthy
    end

    it "has no errors" do
      expect(@service.errors).to be_empty
    end
  end

  shared_examples_for "an unsuccessful service" do
    it "is not a success" do
      expect(@result).to be_falsey
    end

    it "has errors" do
      expect(@service.errors).to be_present
    end

    it "does not assign route to timmi" do
      expect(game.players.first.game_routes.count).to eq 0
    end
  end

  shared_examples_for "a successful route" do
    it_behaves_like "a successful service"

    it "assigns route to timmi" do
      expect(game.players.first.game_routes.count).to eq 1
    end

    it "subtracts 2 trains from timmi" do
      expect(game.players.first.train_cars).to eq(initial_train_cars - route_length)
    end

    it "add points to the player" do
      expect(game.players.first.points).to eq(route_points)
    end

    it "discards train_cards from timmi" do
      expect(game.players.first.game_train_cards.count).to eq(matching_coloured_train_cards.length + matching_locomotive_train_cards.length + nonmatching_coloured_train_cards.length - route_length)
    end

    it "sets the turn player to the voli" do
      expect(game.turn_player.id).to eq(game.players.last.id)
    end

    it "changes the state to playing" do
      expect(game.turn_status).to eq(Game::TURN_STATUS_PLAYING)
    end
  end

  shared_examples_for "a successful begin of last round" do
    it "sets the last_player to timmi" do
      expect(game.last_player).to eq game.players.first
    end

    it "sets the phase to last round" do
      expect(game.phase).to eq Game::PHASE_LAST_ROUND
    end
  end

  describe "#call" do
    before do
      local_game = Game.find(game_id)

      local_game.players.each do |player|
        discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
        expect(discard_service.call).to be_truthy
      end

      local_game.players.first.game_train_cards.each do |card|
        card.play!
        card.save!
      end

      (matching_locomotive_train_cards + matching_coloured_train_cards + nonmatching_coloured_train_cards).each do |c|
        card = local_game.game_train_cards.find { |gtc| gtc.train_card.id == c }
        card.deal_to_player!(local_game.turn_player)
        card.save!
      end

      if route_owner
       local_game_route = GameRoute.for_route(route_id).take
       local_game_route.player = Player.find_by_id(route_owner)
       local_game_route.save!
      end

      if parallel_route_owner
        local_game_route = GameRoute.for_route(parallel_route_id).take
        local_game_route.player = Player.find_by_id(parallel_route_owner)
        local_game_route.save!
      end

      local_game = Game.find(game_id)
      local_game.turn_player.train_cars = initial_train_cars
      local_game.turn_player.save!

      @service = BuildRoute.new(Game.find(game_id), Game.find(game_id).turn_player, route_id, train_card_ids)
      @result = @service.call
    end

    describe "building grey route" do
      let(:route_id) { Game.find(game_id).routes.find { |r| r.from.name == 'Montréal' && r.to.name == 'Boston' }.id }
      let(:parallel_route_id) { Game.find(game_id).routes.find { |r| r.from.name == 'Montréal' && r.to.name == 'Boston' && r.id != route_id }.id }

      context "with explicit list" do
        context "of coloured cards" do
          let(:train_card_ids) { matching_coloured_train_cards }

          context "with 4 train cars left" do
            let(:initial_train_cars) { 4 }
            it_behaves_like "a successful route"
            it_behaves_like "a successful begin of last round"
          end

          context "with 45 train cars left" do
            it_behaves_like "a successful route"
          end
        end

        context "of locomotives" do
          let(:train_card_ids) { matching_locomotive_train_cards }

          it_behaves_like "a successful route"
        end

        context "of coloured and locomotive cards" do
          let(:train_card_ids) { [ matching_locomotive_train_cards.first, matching_coloured_train_cards.first ] }

          it_behaves_like "a successful route"
        end
      end

      context "with auto-selected list" do
        context "of coloured cards" do
          let(:train_card_ids) { matching_coloured_train_cards }
          let(:matching_locomotive_train_cards) { [] }

          it_behaves_like "a successful route"
        end

        context "of locomotive cards" do
          let(:train_card_ids) { matching_locomotive_train_cards }
          let(:matching_coloured_train_cards) { [] }

          it_behaves_like "a successful route"
        end

        context "of mixed locomotive and coloured cards" do
          let(:coloured_take_count) { 1 }
          let(:locomotive_take_count) { 1 }

          it_behaves_like "a successful route"
        end

        context "trains cards have different colours" do
          let(:coloured_take_count) { 1 }
          let(:locomotive_take_count) { 0 }

          it_behaves_like "an unsuccessful service"
        end
      end
    end

    describe "building coloured route" do
      context "with explicit list" do
        context "of coloured cards" do
          let(:train_card_ids) { matching_coloured_train_cards }

          it_behaves_like "a successful route"
        end

        context "of locomotives" do
          let(:train_card_ids) { matching_locomotive_train_cards }

          it_behaves_like "a successful route"
        end

        context "of coloured and locomotive cards" do
          let(:train_card_ids) { [ matching_locomotive_train_cards.first, matching_coloured_train_cards.first ] }

          it_behaves_like "a successful route"
        end
      end

      context "with auto-selected list" do
        context "of coloured cards" do
          let(:train_card_ids) { matching_coloured_train_cards }
          let(:matching_locomotive_train_cards) { [] }

          it_behaves_like "a successful route"
        end

        context "of locomotive cards" do
          let(:train_card_ids) { matching_locomotive_train_cards }
          let(:matching_coloured_train_cards) { [] }

          it_behaves_like "a successful route"
        end

        context "of mixed locomotive and coloured cards" do
          let(:coloured_take_count) { 1 }
          let(:locomotive_take_count) { 1 }

          it_behaves_like "a successful route"
        end

        context "trains cards have different colours" do
          let(:coloured_take_count) { 1 }
          let(:locomotive_take_count) { 0 }

          it_behaves_like "an unsuccessful service"
        end
      end

      context "service fails" do
        context "too few cards" do
          let(:coloured_take_count) { 1 }
          let(:locomotive_take_count) { 0 }
          let(:train_card_ids) { matching_coloured_train_cards }

          it_behaves_like "an unsuccessful service"
        end

        context "too few cars" do
          let(:initial_train_cars) { 1 }

          it_behaves_like "an unsuccessful service"
        end

        context "trains cards have different colours" do
          let(:train_card_ids) { [ matching_coloured_train_cards.first, nonmatching_coloured_train_cards.first ] }

          it_behaves_like "an unsuccessful service"
        end

        context "trains cards have wrong colour" do
          let(:train_card_ids) { nonmatching_coloured_train_cards }

          it_behaves_like "an unsuccessful service"
        end

        context "player does not have train card" do
          let(:train_card_ids) { [ -1, -2 ] }

          it_behaves_like "an unsuccessful service"
        end

        context "invalid routes" do
          describe "with unknown route" do
            let(:route_id) { -1 }

            it_behaves_like "an unsuccessful service"
          end

          describe "with already built route" do
            let(:route_owner) { Game.find(game_id).players.last }

            it_behaves_like "an unsuccessful service"
          end

          describe "with parallel route already built" do
            let(:parallel_route_owner) { Game.find(game_id).players.last }

            it_behaves_like "an unsuccessful service"
          end
        end
      end
    end
  end
end
