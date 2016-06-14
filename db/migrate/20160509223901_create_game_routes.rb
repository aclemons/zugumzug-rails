class CreateGameRoutes < ActiveRecord::Migration
  def change
    create_table :game_routes do |t|
      t.integer :game_id, null: false, :references => "game"
      t.integer :route_id, null: false, :references => "route"
      t.integer :player_id, null: true, :references => "player"

      t.timestamps null: false
    end
  end
end
