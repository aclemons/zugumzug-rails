class AddCompletedToGameDestinationTickets < ActiveRecord::Migration
  def change
    add_column :game_destination_tickets, :completed, :boolean, default: false
  end
end
