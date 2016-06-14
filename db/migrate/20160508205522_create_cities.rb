class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :name, null: false
      t.decimal :latitude, null: false, :precision => 18, :scale => 12
      t.decimal :longitude, null: false, :precision => 18, :scale => 12

      t.timestamps null: false
    end
    add_index :cities, :name, unique: true
  end
end
