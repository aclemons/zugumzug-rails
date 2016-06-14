class DrawTrainCard < AbstractService
  include SortHelper

  def initialize(game, player, train_card_id=nil)
    super(game, player)
    @train_card_id = train_card_id
  end

  def call
    update_game do
      drawn_card = find_card

      unless drawn_card
        if train_card_id.nil?
          errors.add(:base, :no_train_cards_available)
        else
          errors.add(:base, :visible_train_card_with_id_not_found, { train_card_id: train_card_id })
        end

        next false
      end

      unless card_may_be_drawn?(drawn_card)
        byebug
        errors.add(:base, :drawing_faceup_locomotive_not_allowed)
        next false
      end

      drawn_card.deal_to_player!(player)

      save_object(drawn_card)

      if turn_over?(drawn_card)
        game.turn_status = Game::TURN_STATUS_PLAYING
      else
        game.turn_status = Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD
      end

      game.update_game_status!

      save_object(game)

      unless train_card_id.nil?
        turn_over_next_card
      end

      true
    end
  end

  def allowed_phases
    [ Game::PHASE_PLAY, Game::PHASE_LAST_ROUND ]
  end

  def allowed_turn_states
    [ Game::TURN_STATUS_PLAYING, Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD ]
  end

  private

  attr_reader :train_card_id

  def turn_over?(drawn_card)
    drew_second_card? || drew_visible_locomotive?(drawn_card)
  end

  def drew_second_card?
    game.turn_status == Game::TURN_STATUS_DRAWING_SECOND_TRAIN_CARD
  end

  def drew_visible_locomotive?(drawn_card)
    (train_card_id && drawn_card.train_card.locomotive?)
  end

  def card_may_be_drawn?(drawn_card)
    return true if train_card_id.nil?

    if drawn_card.train_card.locomotive?
      game.turn_status == Game::TURN_STATUS_PLAYING
    else
      true
    end
  end

  def find_card
    if train_card_id.nil?
      find_next_card_in_deck
    else
      find_face_up_card
    end
  end

  def find_next_card_in_deck
    loop do
      card = game.game_train_cards.next_deck_card.first

      return card unless card.nil?

      unless sort_played_train_cards
        break
      end

      game.game_train_cards.reload
    end

    nil
  end

  def find_face_up_card
    game.game_train_cards.face_up_card(train_card_id).first
  end

  def turn_over_next_card
    until visible_train_cards_count == Game::VISIBLE_TRAIN_CARD_COUNT
      card = find_next_card_in_deck

      if card
        card.turn_over!
        save_object(card)
      else
        break
      end

      if visible_locomotive_count > Game::MAX_VISIBLE_LOCOMOTIVES
        discard_face_up_train_cards
      end
    end
  end

  def sort_played_train_cards
    played = game.game_train_cards.played.to_a

    return false if played.empty?

    random_sort!(played)

    played.each_with_index do |card, i|
      card.shuffle_to_position!(i)
      save_object(card)
    end

    true
  end

  def discard_face_up_train_cards
    game.game_train_cards.face_up.each do |card|
      card.discard!
      save_object(card)
    end
  end

  def visible_train_cards_count
    game.game_train_cards.face_up.count
  end

  def visible_locomotive_count
    game.game_train_cards.face_up.locomotives.count
  end
end
