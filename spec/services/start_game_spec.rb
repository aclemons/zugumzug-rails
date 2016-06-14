require 'rails_helper'

RSpec.describe StartGame do
  let(:user1) { User.create!({ name: 'timmi', email: 'timmi@powershop.co.nz', password: 'power365' }) }
  let(:user2) { User.create!({ name: 'voli', email: 'voli@powershop.co.nz', password: 'power365' }) }
  let(:player_data) { [ { 'colour' => Colour::RED, 'user_id' => user1.id, 'game_id' => game_id }, { 'colour' => Colour::BLACK, 'user_id' => user2.id, 'game_id' => game_id } ] }

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

  shared_examples_for "a successfully started game" do
    it_behaves_like "a successful service"

    it "sets the phase of the game to initial" do
      expect(game.phase).to eq Game::PHASE_INITIAL
    end

    it "sets the turn status to waiting to discard" do
      expect(game.turn_status).to eq Game::TURN_STATUS_WAITING_TO_DISCARD
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

    it "creates two players in the game"do
      expect(game.players.count).to eq 2
    end

    it "is timmi's turn" do
      expect(game.turn_player.user.id).to eq user1.id
    end

    it "assigns the correct colour to timmi" do
      expect(game.players.first.colour).to eq Colour::RED
    end

    it "assigns 3 destination tickets to timmi" do
      expect(game.players.first.destination_tickets.count).to eq 3
    end

    it "assigns 4 train cards to timmi" do
      expect(game.players.first.train_cards.count).to eq 4
    end

    it "initialises the train count to 45 for timmi" do
      expect(game.players.first.train_cars).to eq 45
    end

    it "assigns the correct colour to voli" do
      expect(game.players.last.colour).to eq Colour::BLACK
    end

    it "assigns 3 destination tickets to voli" do
      expect(game.players.last.destination_tickets.count).to eq 3
    end

    it "assigns 4 train cards to voli" do
      expect(game.players.last.train_cards.count).to eq 4
    end

    it "initialises the train count to 45 for voli" do
      expect(game.players.last.train_cars).to eq 45
    end

    it "turns over 5 train cards" do
      expect(game.game_train_cards.face_up.count).to eq 5
    end

    it "leaves 2 or fewer visible locomotives" do
      expect(game.game_train_cards.face_up.locomotives.count).to be <= 2
    end
  end

  describe "#call" do
    let(:game_id) { @create_game_service.game.id }
    let(:game) { Game.find_by_id(@create_game_service.game.id) }
    let(:force_locomotives) { false }
    before do
      @create_game_service = CreateGame.new()
      @create_game_service.call

      add_player_service = AddPlayer.new(Game.find(game_id), Player.new(player_data[0]))
      add_player_service.call

      add_player_service = AddPlayer.new(Game.find(game_id), Player.new(player_data[1]))
      add_player_service.call

      if force_locomotives
        local_game = Game.find(game_id)
        local_game.game_train_cards.where('deck_position >= ? and deck_position <= ?', (StartGame::TRAIN_CARD_DEAL_SIZE * player_data.count), (StartGame::TRAIN_CARD_DEAL_SIZE * player_data.count) + Game::MAX_VISIBLE_LOCOMOTIVES + 1).each_with_index do |game_card, index|
          next if game_card.train_card.locomotive?

          offset = 0
          swap_card = nil
          loop do
            swap_card = local_game.game_train_cards.where('deck_position = ?', (11 + index + offset)).limit(1).take!

            break if swap_card.train_card.locomotive?

            offset += 1
          end

          first_position = game_card.deck_position
          second_position = swap_card.deck_position

          game_card.deck_position = 100
          game_card.save!

          swap_card.deck_position = first_position
          swap_card.save!

          game_card.deck_position = second_position
          game_card.save!
        end
      end

      @service = StartGame.new(Game.find(game_id))
      @result = @service.call
    end

    context "with less then two locomotives cards" do
      it_behaves_like "a successfully started game"
    end

    context "initial deals shows 3 locomotive cards" do
      let(:force_locomotives) { true }
      it_behaves_like "a successfully started game"
    end
  end
end
