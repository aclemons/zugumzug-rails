class DestinationTicket < ActiveRecord::Base
  belongs_to :from, class_name: 'City', foreign_key: 'from_id'
  belongs_to :to, class_name: 'City', foreign_key: 'to_id'
  validates :points, numericality: { only_integer: true, :greater_than_or_equal_to => 1 }
end
