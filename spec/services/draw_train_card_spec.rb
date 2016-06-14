require 'rails_helper'

RSpec.describe DrawTrainCard do
  let(:destination_ids) { [] }
  let(:game_id) do
    Game.all.last.id
  end
  let(:game) { Game.find_by_id(game_id) }
  let(:train_card_id) { nil }
  let(:initial_card_count) { 4 }
  let(:player_card_count) { initial_card_count + 1 }
  let(:other_player_card_count) { initial_card_count }
  let(:turn_status) { Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD }

  shared_examples_for "a successful service" do
    it "is a success" do
      expect(@result).to be_truthy
    end

    it "has no errors" do
      expect(@service.errors.any?).to be_falsey
    end
  end

  shared_examples_for "a draw" do
    it "assigns 1 new train card to timmi" do
      expect(game.players.first.game_train_cards.count).to eq player_card_count
    end

    it "does not touch voli's cards" do
      expect(game.players.last.game_train_cards.count).to eq other_player_card_count
    end

    it "leave max #{Game::MAX_VISIBLE_LOCOMOTIVES} locomotives visible" do
      expect(game.game_train_cards.face_up.locomotives.count).to be <= Game::MAX_VISIBLE_LOCOMOTIVES
    end
  end

  shared_examples_for "a successful first draw" do
    it_behaves_like "a successful service"

   it "leaves the turn player as timmi" do
      expect(game.turn_player.id).to eq(game.players.first.id)
    end

    it "changes the state to drawing second card" do
      expect(game.turn_status).to eq(Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD)
    end

    it_behaves_like "a draw"
  end

  shared_examples_for "a successful second draw" do
    it_behaves_like "a successful service"

    it "sets the turn player to the voli" do
      expect(game.turn_player.id).to eq(game.players.last.id)
    end

    it "changes the state to playing" do
      expect(game.turn_status).to eq(Game::TURN_STATUS_PLAYING)
    end

    it_behaves_like "a draw"
  end

  shared_examples_for "an unsuccessful service" do
    it "is not a success" do
      expect(@result).to be_falsey
    end

    it "has errors" do
      expect(@service.errors.any?).to be_truthy
    end
  end

  shared_examples_for "a failed draw" do
    it_behaves_like "an unsuccessful service"

    it "assigns no new train cards to timmi" do
      expect(game.players.first.game_train_cards.count).to eq initial_card_count
    end

    it "does not touch voli's tickets" do
      expect(game.players.last.game_train_cards.count).to eq initial_card_count
    end

    it "leaves the turn player as timmi" do
      expect(game.turn_player.id).to eq(game.players.first.id)
    end

    it "leaves the state unchanged" do
      expect(game.turn_status).to eq(turn_status)
    end
  end

  context "drawing blind cards" do
    context "first card" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        @service = DrawTrainCard.new(Game.find(game_id), Game.find(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful first draw"
    end

    context "second card" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.turn_status = Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD
        local_game.save!

        @service = DrawTrainCard.new(Game.find(game_id), Game.find(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful second draw"
    end

    context "no cards left in deck - reshuffle required" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.game_train_cards.unassigned.each { |card| card.status = GameTrainCard::STATE_PLAYED;  card.save! }

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful first draw"
    end

    context "all cards assigned" do
      let(:turn_status) { Game::TURN_STATUS_PLAYING }
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.game_train_cards.unassigned.each { |card| card.status = GameTrainCard::STATE_ASSIGNED;  card.save! }

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a failed draw"
    end
  end

  context "drawing face-up cards" do
    let(:train_card_id) { Game.find_by_id(game_id).game_train_cards.face_up.not_of_colour(Colour::NONE).take.train_card.id }

    context "first card" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful first draw"

      it "uncovers the next card" do
        expect(game.game_train_cards.face_up.count).to eq 5
      end
    end

    context "second card" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.turn_status = Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD
        local_game.save!

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful second draw"

      it "changes the state to playing" do
        expect(game.turn_status).to eq(Game::TURN_STATUS_PLAYING)
      end
    end

    context "no cards left in deck - reshuffle required" do
      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.game_train_cards.unassigned.each { |card| card.play! ; card.save! }

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful first draw"
    end

    context "after draw, three locomotives visible - reshuffle required" do
      let(:train_card_id) { Game.find_by_id(game_id).game_train_cards.face_up.not_of_colour(Colour::NONE).take.train_card.id }

      before do
        local_game = Game.find(game_id)

        locomotive_count = local_game.game_train_cards.face_up.locomotives.count
        locomotives_to_stage = 3 - locomotive_count

        until locomotives_to_stage == local_game.game_train_cards.unassigned.deck_order.take(locomotives_to_stage).reduce(0) { |sum, game_train_card| sum + (game_train_card.train_card.locomotive? ? 1 : 0)  }
          local_game.game_train_cards.unassigned.deck_order.each do |next_card|
            next if next_card.train_card.locomotive?

            next_card.discard!
            next_card.save!

            break
          end
        end

        if locomotive_count < 2
          1.upto(2 - locomotive_count) do |iteration|
            card = local_game.game_train_cards.face_up.not_of_colour(Colour::NONE).first
            card.discard!
            card.save!

            next_card = local_game.game_train_cards.next_deck_card.first
            next_card.turn_over!
            next_card.save!
          end
        end

        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        @service = DrawTrainCard.new(Game.find(game_id), Game.find(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      it_behaves_like "a successful first draw"
    end

    context "locomotives" do
      let(:train_card_id) { Game.find_by_id(game_id).game_train_cards.face_up.locomotives.take.train_card.id }
      let(:turn_status) { Game::TURN_STATUS_PLAYING }

      before do
        Game.find_by_id(game_id).players.each do |player|
          discard_service = DiscardDestinationTickets.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, [])
          expect(discard_service.call).to be_truthy
        end

        local_game = Game.find_by_id(game_id)
        local_game.turn_status = turn_status
        local_game.save!

        unless local_game.game_train_cards.face_up.locomotives.limit(1).take
          card = local_game.game_train_cards.face_up.limit(1).take
          card.play!
          card.save!

          card = local_game.game_train_cards.unassigned.locomotives.limit(1).take
          card.turn_over!
          card.save!
        end

        @service = DrawTrainCard.new(Game.find(game_id), Game.find_by_id(game_id).turn_player, train_card_id)
        @result = @service.call
      end

      context "first draw" do
        it_behaves_like "a successful second draw"

        it "uncovers the next card" do
          expect(game.game_train_cards.face_up.count).to eq 5
        end
      end

      context "second_draw" do
        let(:turn_status) { Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD }

        it_behaves_like "a failed draw"
      end
    end
  end
end
