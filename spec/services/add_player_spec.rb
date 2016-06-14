require 'rails_helper'

RSpec.describe AddPlayer do
  let(:timmi) { User.create!({ name: 'timmi', email: 'timmi@powershop.co.nz', password: 'power365' }) }
  let(:player_data) { { 'colour' => Colour::BLACK, 'user_id' => timmi.id, 'name'=> 'timmi player', 'game_id' => game_id } }
  let(:expected_player_name) { 'timmi player' }

  shared_examples_for "a successful service" do
    it "is a success" do
      expect(@result).to be_truthy
    end

    it "has no errors" do
      expect(@service.errors.any?).to be_falsey
    end
  end

  shared_examples_for "an unsuccessful service" do
    it "is not a success" do
      expect(@result).to be_falsey
    end

    it "has errors" do
      expect(@service.errors.any?).to be_truthy
    end
  end

  shared_examples_for "a successful addition" do
    it_behaves_like "a successful service"

    it "does not change the game phase" do
      expect(game.phase).to eq Game::PHASE_SETUP
    end

    it "does not change the game turn status" do
      expect(game.turn_status).to eq Game::TURN_STATUS_WAITING_FOR_PLAYERS_TO_JOIN
    end

    it "creates player in the game"do
      expect(game.players.count).to eq 1
    end

    it "assigns the correct colour to timmi" do
      expect(game.players.last.colour).to eq Colour::BLACK
    end

    it "assigns the timmi the correct player name" do
      expect(game.players.last.name).to eq expected_player_name
    end

    it "initialises the train count to 45 for timmi" do
      expect(game.players.last.train_cars).to eq 45
    end
  end

  describe "#call" do
    let(:game_id) { @create_game_service.game.id }
    let(:game) { Game.find_by_id(game_id) }
    before do
      @create_game_service = CreateGame.new()
      @create_game_service.call

      @service = AddPlayer.new(Game.find(@create_game_service.game.id), Player.new(player_data))
      @result = @service.call
    end

    context "first user" do
      it_behaves_like "a successful addition"
    end

    context "without player names" do
      let(:player_data) { { "colour" => Colour::BLACK, "user_id" => timmi.id, 'game_id' => game_id } }
      let(:expected_player_name) { 'timmi' }

      it_behaves_like "a successful addition"
    end
  end
end
