class CreateDestinationTickets < ActiveRecord::Migration
  def change
    create_table :destination_tickets do |t|
      t.integer :from_id, null: false, :references => "city"
      t.integer :to_id, null: false, :references => "city"
      t.integer :points, null: false

      t.timestamps null: false
    end
    add_foreign_key :destination_tickets, :cities, column: :from_id
    add_foreign_key :destination_tickets, :cities, column: :to_id
  end
end
