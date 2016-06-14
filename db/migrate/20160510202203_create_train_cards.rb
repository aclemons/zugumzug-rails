class CreateTrainCards < ActiveRecord::Migration
  def change
    create_table :train_cards do |t|
      t.integer :colour, null: false

      t.timestamps null: false
    end
  end
end
