class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :phase, null: false
      t.integer :turn_status, null: false
      t.integer :turn_player_id, null: true, :references => "player"
      t.integer :last_player_id, null: true, :references => "player"
      t.integer :winning_player_id, null: true, :references => "player"

      t.timestamps null: false
    end
  end
end
