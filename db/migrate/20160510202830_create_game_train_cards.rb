class CreateGameTrainCards < ActiveRecord::Migration
  def change
    create_table :game_train_cards do |t|
      t.integer :game_id, null: false, :references => "game"
      t.integer :train_card_id, null: false, :references => "train_card"
      t.integer :player_id, null: true, :references => "player"
      t.integer :status, null: false
      t.integer :deck_position, null: false

      t.timestamps null: false
    end
  end
end
