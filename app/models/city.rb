class City < ActiveRecord::Base
  LONG_LAT_MAX = 180.0
  LONG_LAT_MIN = LONG_LAT_MAX * -1

  validates :name, presence: true, length: { minimum: 1, maximum: 50 },
                   uniqueness: true

  validates :latitude, presence: true, numericality: { only_integer: false, :greater_than_or_equal_to => LONG_LAT_MIN, :less_than_or_equal_to => LONG_LAT_MAX }
  validates :longitude, presence: true, numericality: { only_integer: false, :greater_than_or_equal_to => LONG_LAT_MIN, :less_than_or_equal_to => LONG_LAT_MAX }

  scope :with_name, -> (name) { where name: name }
end

