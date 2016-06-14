class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.integer :game_id, null: false, :references => "game"
      t.integer :user_id, null: false, :references => "user"
      t.string  :name, null: false
      t.integer :colour, null: false
      t.integer :train_cars, null: false
      t.integer :position, null: false
      t.integer :points, null: false
      t.boolean :longest_continuous_path, null: false

      t.timestamps null: false
    end

    add_index :players, [:game_id, :name], unique: true
    add_index :players, [:game_id, :colour], unique: true
    add_index :players, [:game_id, :position], unique: true
  end
end
