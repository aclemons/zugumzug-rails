require 'rails_helper'

RSpec.describe DrawDestinationTickets do
  let(:destination_ids) { [] }
  let(:game_id) do
    Game.all.last.id
  end
  let(:game) { Game.find(game_id) }

  shared_examples_for "a successful service" do
    it "is a success" do
      expect(@result).to be_truthy
    end

    it "has no errors" do
      expect(@service.errors.any?).to be_falsey
    end
  end

  shared_examples_for "a successful draw" do
    it_behaves_like "a successful service"

    it "assigns 3 new cards to timmi" do
      expect(game.players.first.game_destination_tickets.where(game_destination_tickets: { status: GameDestinationTicket::STATE_PENDING }).count).to eq 3
    end

    it "timmi still has 3 other tickets" do
      expect(game.players.first.game_destination_tickets.where.not(game_destination_tickets: { status: GameDestinationTicket::STATE_ASSIGNED }).count).to eq 3
    end

    it "does not touch voli's tickets" do
      expect(game.players.last.game_destination_tickets.where.not(game_destination_tickets: { status: GameDestinationTicket::STATE_ASSIGNED }).count).to eq 0
    end

    it "leaves the turn player as timmi" do
      expect(game.turn_player.id).to eq(game.players.first.id)
    end

    it "changes the state to waiting" do
      expect(game.turn_status).to eq(Game::TURN_STATUS_WAITING_TO_DISCARD)
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

  shared_examples_for "an unsuccessful draw" do
    it_behaves_like "an unsuccessful service"

    it "assigns no cards to timmi" do
      expect(game.players.first.game_destination_tickets.where.not(game_destination_tickets: { status: GameDestinationTicket::STATE_ASSIGNED }).count).to eq 0
    end

    it "timmi still has 3 other tickets" do
      expect(game.players.first.game_destination_tickets.where(game_destination_tickets: { status: GameDestinationTicket::STATE_ASSIGNED }).count).to be > 3
    end

    it "does not touch voli's tickets" do
      expect(game.players.last.game_destination_tickets.where.not(game_destination_tickets: { status: GameDestinationTicket::STATE_ASSIGNED }).count).to eq 0
    end

    it "leaves the turn player as timmi" do
      expect(game.turn_player.id).to eq(game.players.first.id)
    end

    it "leaves the turn status" do
      expect(game.turn_status).to eq(Game::TURN_STATUS_PLAYING)
    end
  end

  context "drawing is allowed" do
    before do
      Game.find(game_id).players.each do |player|
        discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
        expect(discard_service.call).to be_truthy
      end

      @service = DrawDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player)
      @result = @service.call
    end

    it_behaves_like "a successful draw"
  end

  context "reshuffle is required" do
    before do
      Game.find(game_id).players.each do |player|
        discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
        expect(discard_service.call).to be_truthy
      end

      Game.find(game_id).game_destination_tickets.unassigned.each { |t| t.status = GameDestinationTicket::STATE_DISCARDED; t.save! }

      @service = DrawDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player)
      @result = @service.call
    end

    it_behaves_like "a successful draw"
  end

  context "no destination tickets remaining" do
    before do
      Game.find(game_id).players.each do |player|
        discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
        expect(discard_service.call).to be_truthy
      end

      Game.find(game_id).game_destination_tickets.unassigned.each_with_index { |t, index| t.status = GameDestinationTicket::STATE_ASSIGNED; t.player = t.game.players[index % 2]; t.save! }

      @service = DrawDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player)
      @result = @service.call
    end

    it_behaves_like "an unsuccessful draw"
  end
end
