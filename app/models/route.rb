class Route < ActiveRecord::Base
  MIN_ROUTE_LENGTH = 1
  MAX_ROUTE_LENGTH = 6

  belongs_to :from, class_name: 'City', foreign_key: 'from_id'
  belongs_to :to, class_name: 'City', foreign_key: 'to_id'

  validates_inclusion_of :colour, :in => Colour::route_colours

  validates :length, numericality: { only_integer: true, :greater_than_or_equal_to => MIN_ROUTE_LENGTH, :less_than_or_equal_to => MAX_ROUTE_LENGTH }

  def grey?
    colour == Colour::NONE
  end

  def points
    case length
    when 1
      1
    when 2
      2
    when 3
      4
    when 4
      7
    when 5
      10
    when 6
      15
    else
      raise "Unknown length: #{length}"
    end
  end
end
