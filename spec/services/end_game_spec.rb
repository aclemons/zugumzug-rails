require 'rails_helper'

RSpec.describe EndGame do
  let(:game_id) do
    local_game = Game.all.last

    # unassign all destination tickets to make tests repeatable
    local_game.players.each do |player|
      player.game_destination_tickets.each do |ticket|
        ticket.player = nil
        ticket.status = GameDestinationTicket::STATE_UNASSIGNED
        ticket.save!
      end
    end

    routes.each do |from, to|
      from_city = City.find_by!(name: from)
      to_city = City.find_by!(name: to)

      game_route = local_game.game_routes.joins(:route).where(routes: { from_id: from_city.id, to_id: to_city.id }).limit(1).take!
      game_route.player = local_game.turn_player
      game_route.save!
    end

    destination_tickets.each do |from, to|
      from_city = City.find_by(name: from)
      to_city = City.find_by(name: to)

      destination_ticket = local_game.game_destination_tickets.joins(:destination_ticket).where(destination_tickets: { from_id: from_city.id }).where(destination_tickets: {to_id: to_city.id }).take!
      destination_ticket.player = local_game.turn_player
      destination_ticket.status = GameDestinationTicket::STATE_ASSIGNED
      destination_ticket.save!
    end

    local_game.phase = Game::PHASE_END
    local_game.save!

    local_game.id
  end
  let(:routes) { [ ['Omaha', 'Duluth'], ['Duluth', 'Chicago'], ['Omaha', 'Chicago'], ['Chicago', 'Pittsburgh'], ['Vancouver', 'Calgary'], ['Omaha', 'Kansas City'], ['Oklahoma City', 'Kansas City'], ['Oklahoma City', 'Dallas'], ['Dallas', 'Houston'] ] }
  let(:destination_tickets) { [ ] }
  let(:game) { Game.find(game_id) }
  let(:errors) { ActiveModel::Errors.new(self) }
  let(:save_callback) {
    Proc.new do |object|
      unless object && object.save
        object.errors.each { |attribute, error| errors.add(attribute, error) } if object
        raise ActiveRecord::Rollback
      end
    end
  }

  describe "#points" do
    before do
      EndGame.new.check_for_completed_routes(Game.find(game_id), Game.find(game_id).players.first, save_callback)
      EndGame.new.check_for_completed_routes(Game.find(game_id), Game.find(game_id).players.last, save_callback)
      EndGame.new.check_for_end_of_game(Game.find(game_id), save_callback)
    end

    context "no destination tickets" do
      context "only timmi has built routes" do
        it "timmi has the correct total points" do
          expect(game.players.first.points).to eq 10
        end

        it "timmi has the continuous path card" do
          expect(game.players.first.longest_continuous_path).to eq(true)
        end
      end
    end

    context "all destination tickets solved" do
      let(:destination_tickets) { [ ['Duluth', 'Houston'] ] }

      it "calculates points for built routes and completed destinations" do
        expect(game.players.first.points).to eq 18
      end
    end

    context "all destination tickets unsolved" do
      let(:destination_tickets) { [ ['Boston', 'Miami'] ] }

      it "calculates points for built routes and completed destinations" do
        expect(game.players.first.points).to eq -2
      end
    end

    context "mixed solved and unsolved destination tickets" do
      let(:destination_tickets) { [ ['Duluth', 'Houston'], ['Boston', 'Miami'] ] }

      it "calculates points for built routes and completed destinations" do
        expect(game.players.first.points).to eq 6
      end
    end
  end
end
