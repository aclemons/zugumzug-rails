require 'rails_helper'

RSpec.describe CreateGame do
  shared_examples_for "a successful service" do
    it "is a success" do
      expect(@result).to be_truthy
    end

    it "has no errors" do
      expect(@service.errors.any?).to be_falsey
    end
  end

  describe "#call" do
    let(:game) { Game.find_by_id(@service.game.id) }
    before do
      @service = CreateGame.new()
      @result = @service.call
    end

    context "with player name" do
      it_behaves_like "a successful service"

      it "assigns game to the created game" do
        expect(@service.game).to be_truthy
      end

      it "sets the phase of the game to initial" do
        expect(game.phase).to eq Game::PHASE_SETUP
      end

      it "sets the turn status to waiting to discard" do
        expect(game.turn_status).to eq Game::TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN
      end

      it "adds 100 routes to the game" do
        expect(game.game_routes.count).to eq 100
      end

      it "leaves all routes unassigned" do
        expect(game.game_routes.joins(:player).where.not(players: { id: nil }).count).to eq 0
      end

      it "adds 30 destination tickets to the game" do
        expect(game.game_destination_tickets.count).to eq 30
      end

      it "adds 110 train cards to the game" do
        expect(game.game_train_cards.count).to eq 110
      end
    end
  end
end
