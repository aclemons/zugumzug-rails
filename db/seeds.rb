# initialise all cities in the game
City.create!([{ name: 'Atlanta', latitude: 33.755, longitude: -84.39 },
              { name: 'Boston', latitude: 42.358056, longitude: -71.063611 },
              { name: 'Calgary', latitude: 51.05, longitude: -114.066667 },
              { name: 'Charleston', latitude: 32.783333, longitude: -79.933333},
              { name: 'Chicago', latitude: 41.836944, longitude: -87.684722 },
              { name: 'Dallas', latitude: 32.775833, longitude: -96.796667 },
              { name: 'Denver', latitude: 39.76185, longitude: -104.881105 },
              { name: 'Duluth', latitude: 46.8, longitude: -92.1 },
              { name: 'El Paso', latitude: 31.790278, longitude: -106.423333 },
              { name: 'Helena', latitude: 46.595806, longitude: -112.027031 },
              { name: 'Houston', latitude: 29.762778, longitude: -95.383056 },
              { name: 'Kansas City', latitude: 39.1, longitude: -94.58 },
              { name: 'Las Vegas', latitude: 36.1318, longitude: -115.184 },
              { name: 'Little Rock', latitude: 34.736111, longitude: -92.331111 },
              { name: 'Los Angeles', latitude: 34.05, longitude: -118.25 },
              { name: 'Miami', latitude: 25.775278, longitude: -80.208889 },
              { name: 'Montréal', latitude: 45.5, longitude: -73.566667 },
              { name: 'Nashville', latitude: 36.166667, longitude: -86.783333 },
              { name: 'New Orleans', latitude: 29.95, longitude: -90.066667 },
              { name: 'New York City', latitude: 40.7127, longitude: -74.0059 },
              { name: 'Oklahoma City', latitude: 35.482222, longitude: -97.535 },
              { name: 'Omaha', latitude: 41.25, longitude: -96 },
              { name: 'Phoenix', latitude: 33.45, longitude: -112.066667 },
              { name: 'Pittsburgh', latitude: 40.439722, longitude: -79.976389 },
              { name: 'Portland', latitude: 45.52, longitude: -122.681944 },
              { name: 'Raleigh', latitude: 35.766667, longitude: -78.633333 },
              { name: 'St. Louis', latitude: 38.627222, longitude: -90.197778 },
              { name: 'Salt Lake City', latitude: 40.75, longitude: -111.883333 },
              { name: 'San Francisco', latitude: 37.783333, longitude: -122.416667 },
              { name: 'Santa Fe', latitude: 35.667222, longitude: -105.964444 },
              { name: 'Sault Ste. Marie', latitude: 46.533333, longitude: -84.35 },
              { name: 'Seattle', latitude: 47.609722, longitude: -122.333056 },
              { name: 'Toronto', latitude: 43.7, longitude: -79.4 },
              { name: 'Vancouver', latitude: 49.25, longitude: -123.1 },
              { name: 'Washington', latitude: 38.904722, longitude: -77.016389 },
              { name: 'Winnipeg', latitude: 49.899444, longitude: -97.139167 }])

# initialise all destination tickets in the game
[ [ 'Boston', 'Miami', 12 ],
  [ 'Calgary', 'Phoenix', 13 ],
  [ 'Calgary', 'Salt Lake City', 7 ],
  [ 'Chicago', 'New Orleans', 7 ],
  [ 'Chicago', 'Santa Fe', 9 ],
  [ 'Dallas', 'New York City', 11 ],
  [ 'Denver', 'El Paso', 4 ],
  [ 'Denver', 'Pittsburgh', 11 ],
  [ 'Duluth', 'El Paso', 10 ],
  [ 'Duluth', 'Houston', 8 ],
  [ 'Helena', 'Los Angeles', 8 ],
  [ 'Kansas City', 'Houston', 5 ],
  [ 'Los Angeles', 'Chicago', 16 ],
  [ 'Los Angeles', 'Miami', 20 ],
  [ 'Los Angeles', 'New York City', 21 ],
  [ 'Montréal', 'Atlanta', 9 ],
  [ 'Montréal', 'New Orleans', 13 ],
  [ 'New York City', 'Atlanta', 6 ],
  [ 'Portland', 'Nashville', 17 ],
  [ 'Portland', 'Phoenix', 11 ],
  [ 'San Francisco', 'Atlanta', 17 ],
  [ 'Sault Ste. Marie', 'Nashville', 8 ],
  [ 'Sault Ste. Marie', 'Oklahoma City', 9 ],
  [ 'Seattle', 'Los Angeles', 9 ],
  [ 'Seattle', 'New York City', 22 ],
  [ 'Toronto', 'Miami', 10 ],
  [ 'Vancouver', 'Montréal', 20 ],
  [ 'Vancouver', 'Santa Fe', 13 ],
  [ 'Winnipeg', 'Houston', 12 ],
  [ 'Winnipeg', 'Little Rock', 11 ] ].each do |data|
  DestinationTicket.create!(from: City.find_by!(name: data[0]), to: City.find_by!(name: data[1]), points: data[2])
end

# initialise all routes in the game
Route.create!(from: City.find_by!(name: 'Vancouver'), to: City.find_by!(name: 'Seattle'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Vancouver'), to: City.find_by!(name: 'Seattle'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Vancouver'), to: City.find_by!(name: 'Calgary'), length: 3, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Seattle'), to: City.find_by!(name: 'Calgary'), length: 4, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Seattle'), to: City.find_by!(name: 'Helena'), length: 6, colour: Colour::YELLOW)

Route.create!(from: City.find_by!(name: 'Portland'), to: City.find_by!(name: 'Seattle'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Portland'), to: City.find_by!(name: 'Seattle'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Portland'), to: City.find_by!(name: 'San Francisco'), length: 5, colour: Colour::GREEN)
Route.create!(from: City.find_by!(name: 'Portland'), to: City.find_by!(name: 'San Francisco'), length: 5, colour: Colour::PURPLE)
Route.create!(from: City.find_by!(name: 'Portland'), to: City.find_by!(name: 'Salt Lake City'), length: 6, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'San Francisco'), to: City.find_by!(name: 'Los Angeles'), length: 3, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'San Francisco'), to: City.find_by!(name: 'Los Angeles'), length: 3, colour: Colour::PURPLE)
Route.create!(from: City.find_by!(name: 'San Francisco'), to: City.find_by!(name: 'Salt Lake City'), length: 5, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'San Francisco'), to: City.find_by!(name: 'Salt Lake City'), length: 5, colour: Colour::ORANGE)

Route.create!(from: City.find_by!(name: 'Los Angeles'), to: City.find_by!(name: 'Las Vegas'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Los Angeles'), to: City.find_by!(name: 'Phoenix'), length: 3, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Los Angeles'), to: City.find_by!(name: 'El Paso'), length: 6, colour: Colour::BLACK)

Route.create!(from: City.find_by!(name: 'Calgary'), to: City.find_by!(name: 'Helena'), length: 4, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Calgary'), to: City.find_by!(name: 'Winnipeg'), length: 6, colour: Colour::WHITE)

Route.create!(from: City.find_by!(name: 'Helena'), to: City.find_by!(name: 'Denver'), length: 4, colour: Colour::GREEN)
Route.create!(from: City.find_by!(name: 'Helena'), to: City.find_by!(name: 'Winnipeg'), length: 4, colour: Colour::BLUE)
Route.create!(from: City.find_by!(name: 'Helena'), to: City.find_by!(name: 'Duluth'), length: 6, colour: Colour::ORANGE)
Route.create!(from: City.find_by!(name: 'Helena'), to: City.find_by!(name: 'Omaha'), length: 5, colour: Colour::RED)
Route.create!(from: City.find_by!(name: 'Helena'), to: City.find_by!(name: 'Salt Lake City'), length: 3, colour: Colour::PURPLE)

Route.create!(from: City.find_by!(name: 'Salt Lake City'), to: City.find_by!(name: 'Denver'), length: 3, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'Salt Lake City'), to: City.find_by!(name: 'Denver'), length: 3, colour: Colour::RED)

Route.create!(from: City.find_by!(name: 'Las Vegas'), to: City.find_by!(name: 'Salt Lake City'), length: 3, colour: Colour::ORANGE)

Route.create!(from: City.find_by!(name: 'Phoenix'), to: City.find_by!(name: 'El Paso'), length: 3, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Phoenix'), to: City.find_by!(name: 'Denver'), length: 5, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'Phoenix'), to: City.find_by!(name: 'Santa Fe'), length: 3, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Winnipeg'), to: City.find_by!(name: 'Sault Ste. Marie'), length: 6, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Winnipeg'), to: City.find_by!(name: 'Duluth'), length: 4, colour: Colour::BLACK)

Route.create!(from: City.find_by!(name: 'Denver'), to: City.find_by!(name: 'Omaha'), length: 4, colour: Colour::PURPLE)
Route.create!(from: City.find_by!(name: 'Denver'), to: City.find_by!(name: 'Kansas City'), length: 4, colour: Colour::ORANGE)
Route.create!(from: City.find_by!(name: 'Denver'), to: City.find_by!(name: 'Kansas City'), length: 4, colour: Colour::BLACK)
Route.create!(from: City.find_by!(name: 'Denver'), to: City.find_by!(name: 'Oklahoma City'), length: 4, colour: Colour::RED)

Route.create!(from: City.find_by!(name: 'Santa Fe'), to: City.find_by!(name: 'Denver'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Santa Fe'), to: City.find_by!(name: 'Oklahoma City'), length: 3, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'El Paso'), to: City.find_by!(name: 'Santa Fe'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'El Paso'), to: City.find_by!(name: 'Oklahoma City'), length: 5, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'El Paso'), to: City.find_by!(name: 'Dallas'), length: 4, colour: Colour::RED)
Route.create!(from: City.find_by!(name: 'El Paso'), to: City.find_by!(name: 'Houston'), length: 6, colour: Colour::GREEN)

Route.create!(from: City.find_by!(name: 'Duluth'), to: City.find_by!(name: 'Sault Ste. Marie'), length: 3, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Duluth'), to: City.find_by!(name: 'Toronto'), length: 6, colour: Colour::PURPLE)
Route.create!(from: City.find_by!(name: 'Duluth'), to: City.find_by!(name: 'Chicago'), length: 3, colour: Colour::RED)

Route.create!(from: City.find_by!(name: 'Omaha'), to: City.find_by!(name: 'Duluth'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Omaha'), to: City.find_by!(name: 'Duluth'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Omaha'), to: City.find_by!(name: 'Kansas City'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Omaha'), to: City.find_by!(name: 'Kansas City'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Omaha'), to: City.find_by!(name: 'Chicago'), length: 4, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'Kansas City'), to: City.find_by!(name: 'St. Louis'), length: 2, colour: Colour::PURPLE)
Route.create!(from: City.find_by!(name: 'Kansas City'), to: City.find_by!(name: 'St. Louis'), length: 2, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'Oklahoma City'), to: City.find_by!(name: 'Kansas City'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Oklahoma City'), to: City.find_by!(name: 'Kansas City'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Oklahoma City'), to: City.find_by!(name: 'Little Rock'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Oklahoma City'), to: City.find_by!(name: 'Dallas'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Oklahoma City'), to: City.find_by!(name: 'Dallas'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Dallas'), to: City.find_by!(name: 'Little Rock'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Dallas'), to: City.find_by!(name: 'Houston'), length: 1, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Dallas'), to: City.find_by!(name: 'Houston'), length: 1, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Houston'), to: City.find_by!(name: 'New Orleans'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Sault Ste. Marie'), to: City.find_by!(name: 'Montréal'), length: 5, colour: Colour::BLACK)
Route.create!(from: City.find_by!(name: 'Sault Ste. Marie'), to: City.find_by!(name: 'Toronto'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Chicago'), to: City.find_by!(name: 'Toronto'), length: 4, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'Chicago'), to: City.find_by!(name: 'Pittsburgh'), length: 3, colour: Colour::BLACK)
Route.create!(from: City.find_by!(name: 'Chicago'), to: City.find_by!(name: 'Pittsburgh'), length: 3, colour: Colour::ORANGE)

Route.create!(from: City.find_by!(name: 'St. Louis'), to: City.find_by!(name: 'Chicago'), length: 2, colour: Colour::GREEN)
Route.create!(from: City.find_by!(name: 'St. Louis'), to: City.find_by!(name: 'Chicago'), length: 2, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'St. Louis'), to: City.find_by!(name: 'Pittsburgh'), length: 5, colour: Colour::GREEN)
Route.create!(from: City.find_by!(name: 'St. Louis'), to: City.find_by!(name: 'Nashville'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Little Rock'), to: City.find_by!(name: 'St. Louis'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Little Rock'), to: City.find_by!(name: 'Nashville'), length: 3, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'Little Rock'), to: City.find_by!(name: 'New Orleans'), length: 3, colour: Colour::GREEN)

Route.create!(from: City.find_by!(name: 'New Orleans'), to: City.find_by!(name: 'Atlanta'), length: 4, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'New Orleans'), to: City.find_by!(name: 'Atlanta'), length: 4, colour: Colour::ORANGE)
Route.create!(from: City.find_by!(name: 'New Orleans'), to: City.find_by!(name: 'Miami'), length: 6, colour: Colour::RED)

Route.create!(from: City.find_by!(name: 'Nashville'), to: City.find_by!(name: 'Pittsburgh'), length: 4, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'Nashville'), to: City.find_by!(name: 'Raleigh'), length: 3, colour: Colour::BLACK)
Route.create!(from: City.find_by!(name: 'Nashville'), to: City.find_by!(name: 'Atlanta'), length: 1, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Atlanta'), to: City.find_by!(name: 'Raleigh'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Atlanta'), to: City.find_by!(name: 'Raleigh'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Atlanta'), to: City.find_by!(name: 'Charleston'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Atlanta'), to: City.find_by!(name: 'Miami'), length: 5, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'Toronto'), to: City.find_by!(name: 'Montréal'), length: 3, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Pittsburgh'), to: City.find_by!(name: 'Toronto'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Pittsburgh'), to: City.find_by!(name: 'New York City'), length: 2, colour: Colour::GREEN)
Route.create!(from: City.find_by!(name: 'Pittsburgh'), to: City.find_by!(name: 'New York City'), length: 2, colour: Colour::WHITE)
Route.create!(from: City.find_by!(name: 'Pittsburgh'), to: City.find_by!(name: 'Washington'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Pittsburgh'), to: City.find_by!(name: 'Raleigh'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Raleigh'), to: City.find_by!(name: 'Washington'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Raleigh'), to: City.find_by!(name: 'Washington'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Charleston'), to: City.find_by!(name: 'Raleigh'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'Miami'), to: City.find_by!(name: 'Charleston'), length: 4, colour: Colour::PURPLE)

Route.create!(from: City.find_by!(name: 'Montréal'), to: City.find_by!(name: 'Boston'), length: 2, colour: Colour::NONE)
Route.create!(from: City.find_by!(name: 'Montréal'), to: City.find_by!(name: 'Boston'), length: 2, colour: Colour::NONE)

Route.create!(from: City.find_by!(name: 'New York City'), to: City.find_by!(name: 'Boston'), length: 2, colour: Colour::RED)
Route.create!(from: City.find_by!(name: 'New York City'), to: City.find_by!(name: 'Boston'), length: 2, colour: Colour::YELLOW)
Route.create!(from: City.find_by!(name: 'New York City'), to: City.find_by!(name: 'Montréal'), length: 3, colour: Colour::BLUE)

Route.create!(from: City.find_by!(name: 'Washington'), to: City.find_by!(name: 'New York City'), length: 2, colour: Colour::BLACK)
Route.create!(from: City.find_by!(name: 'Washington'), to: City.find_by!(name: 'New York City'), length: 2, colour: Colour::ORANGE)

# initialise train cards
[ Colour::BLACK, Colour::BLUE, Colour::GREEN, Colour::ORANGE, Colour::PURPLE, Colour::RED, Colour::WHITE, Colour::YELLOW ].each do |colour|
  (1..12).each do |i|
    TrainCard.create!({ colour: colour})
  end
end

# initialise wilcards (locomotives)
(1..14).each do |i|
  TrainCard.create!({ colour: Colour::NONE})
end
