class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.integer :from_id, null: false, :references => "city"
      t.integer :to_id, null: false, :references => "city"
      t.integer :colour, null: false
      t.integer :length, null: false

      t.timestamps null: false
    end
  end
end