require 'rails_helper'

RSpec.describe DiscardDestinationTickets do
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

  shared_examples_for "an unsuccessful service" do
    it "is not a success" do
      expect(@result).to be_falsey
    end

    it "has errors" do
      expect(@service.errors.any?).to be_truthy
    end
  end

  shared_examples_for "an unsuccessful discard" do
    it_behaves_like "an unsuccessful service"

    it "leaves the turn player as timmi" do
      expect(game.turn_player.id).to eq(game.players.first.id)
    end
  end

  context "initial game phase" do
    before do
      @service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, destination_ids)
      @result = @service.call
    end

    context "discarding no tickets" do
      it_behaves_like "a successful service"

      it "marks all of timmi's tickets as assigned" do
        expect(game.players.first.game_destination_tickets.assigned.count).to eq 3
      end

      it "timmi has no other tickets" do
        expect(game.players.first.game_destination_tickets.not_assigned.count).to eq 0
      end

      it "does not touch voli's tickets" do
        expect(game.players.last.game_destination_tickets.not_assigned.count).to eq 3
      end

      it "sets the turn player as voli" do
        expect(game.turn_player.id).to eq(game.players.last.id)
      end
    end

    context "discarding 1 ticket" do
      let(:destination_ids) { [ Game.find(game_id).players.first.game_destination_tickets.first.destination_ticket.id ] }

      it_behaves_like "a successful service"

      it "marks timmi's other tickets as assigned" do
        expect(game.players.first.game_destination_tickets.assigned.count).to eq 2
      end

      it "discards the matching ticket" do
        expect(game.players.first.game_destination_tickets.map { |t| t.destination_ticket.id}).not_to include(destination_ids[0])
      end

      it "timmi has no other tickets" do
        expect(game.players.first.game_destination_tickets.not_assigned.count).to eq 0
      end

      it "does not touch voli's tickets" do
        expect(game.players.last.game_destination_tickets.not_assigned.count).to eq 3
      end

      it "sets the turn player as voli" do
        expect(game.turn_player.id).to eq(game.players.last.id)
      end
    end

    context "discarding 2 tickets" do
      let(:destination_ids) { 2.times.each_with_object([]) { |i, arr| arr << Game.find(game_id).players.first.game_destination_tickets[i].destination_ticket.id } }

      it_behaves_like "an unsuccessful service"

      it "leaves the turn player as timmi" do
        expect(game.turn_player.id).to eq(game.players.first.id)
      end
    end
  end

  context "playing game phase" do
    before do
      Game.find(game_id).players.each do |player|
        discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
        expect(discard_service.call).to be_truthy
      end

      local_game = Game.find(game_id)
      local_game.turn_status = Game::TURN_STATUS_WAITING_TO_DISCARD
      local_game.save!

      local_game.game_destination_tickets.unassigned.limit(3).each do |t|
        t.player = local_game.turn_player
        t.status = GameDestinationTicket::STATE_PENDING
        t.save!
      end

      @service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, destination_ids)
      @result = @service.call
    end

    context "discarding no tickets" do
      it_behaves_like "a successful service"

      it "marks all of timmi's tickets as assigned" do
        expect(game.players.first.game_destination_tickets.assigned.count).to eq 6
      end

      it "timmi has no other tickets" do
        expect(game.players.first.game_destination_tickets.not_assigned.count).to eq 0
      end

      it "does not touch voli's tickets" do
        expect(game.players.last.game_destination_tickets.not_assigned.count).to eq 0
        expect(game.players.last.game_destination_tickets.assigned.count).to eq 3
      end

      it "sets the turn player as voli" do
        expect(game.turn_player.id).to eq(game.players.last.id)
      end
    end

    context "discarding 1 ticket" do
      let(:destination_ids) { [ Game.find(game_id).players.first.game_destination_tickets[3].destination_ticket.id ] }

      it_behaves_like "a successful service"

      it "marks timmi's other tickets as assigned" do
        expect(game.players.first.game_destination_tickets.assigned.count).to eq 5
      end

      it "discards the matching ticket" do
        expect(game.players.first.game_destination_tickets.map { |t| t.destination_ticket.id}).not_to include(destination_ids[0])
      end

      it "timmi has no other tickets" do
        expect(game.players.first.game_destination_tickets.not_assigned.count).to eq 0
      end

      it "does not touch voli's tickets" do
        expect(game.players.last.game_destination_tickets.not_assigned.count).to eq 0
        expect(game.players.last.game_destination_tickets.assigned.count).to eq 3
      end

      it "sets the turn player as voli" do
        expect(game.turn_player.id).to eq(game.players.last.id)
      end
    end

    context "discarding invalid ticket status" do
      let(:destination_ids) { [ Game.find(game_id).players.first.game_destination_tickets.first.destination_ticket.id ] }

      it_behaves_like "an unsuccessful discard"
    end

    context "discarding other voli's ticket" do
      let(:destination_ids) { [ Game.find(game_id).players.last.game_destination_tickets.first.destination_ticket.id ] }

      it_behaves_like "an unsuccessful discard"
    end

    context "discarding 2 tickets" do
      let(:destination_ids) { (3..4).each_with_object([]) { |i, arr| arr << Game.find(game_id).players.first.game_destination_tickets[i].destination_ticket.id } }

      it_behaves_like "a successful service"

      it "marks timmi's other tickets as assigned" do
        expect(game.players.first.game_destination_tickets.assigned.count).to eq 4
      end

      it "discards the matching ticket" do
        expect(game.players.first.game_destination_tickets.map { |t| t.destination_ticket.id}).not_to include(destination_ids[0])
      end

      it "timmi has no other tickets" do
        expect(game.players.first.game_destination_tickets.not_assigned.count).to eq 0
      end

      it "does not touch voli's tickets" do
        expect(game.players.last.game_destination_tickets.not_assigned.count).to eq 0
        expect(game.players.last.game_destination_tickets.assigned.count).to eq 3
      end

      it "set the turn player as voli" do
        expect(game.turn_player.id).to eq(game.players.last.id)
      end
    end

    context "discarding all tickets" do
      let(:destination_ids) { (3..5).each_with_object([]) { |i, arr| arr << Game.find(game_id).players.first.game_destination_tickets[i].destination_ticket.id } }

      it_behaves_like "an unsuccessful discard"
    end
  end
end
