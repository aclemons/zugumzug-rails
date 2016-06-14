class CreateGameDestinationTickets < ActiveRecord::Migration
  def change
    create_table :game_destination_tickets do |t|
      t.integer :game_id, null: false, :references => "game"
      t.integer :destination_ticket_id, null: false, :references => "destination_ticket"
      t.integer :player_id, null: true, :references => "player"
      t.integer :status, null: false
      t.integer :deck_position, null: false

      t.timestamps null: false
    end
  end
end
