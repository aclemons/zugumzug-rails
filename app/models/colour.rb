class Colour
  BLACK = 1
  BLUE = 2
  GREEN = 3
  NONE = 0
  ORANGE = 4
  PURPLE = 5
  RED = 6
  WHITE = 7
  YELLOW = 8

  def self.name(colour, train_card_mode=false)
    case colour
    when BLACK
      "black"
    when BLUE
      "blue"
    when GREEN
      "green"
    when ORANGE
      "orange"
    when PURPLE
      "purple"
    when RED
      "red"
    when WHITE
      "white"
    when YELLOW
      "yellow"
    when NONE
      train_card_mode ? "locomotive" : "grey"
    else
      raise
    end
  end

  def self.html_name(colour)
    colour == Colour::WHITE ? "#FDF5E6" : Colour.name(colour, false)
  end

  def self.route_colours
    [ BLACK, BLUE, GREEN, NONE, ORANGE, PURPLE, RED, WHITE, YELLOW ]
  end

  def self.train_card_colours
    [ BLACK, BLUE, GREEN, NONE, ORANGE, PURPLE, RED, WHITE, YELLOW ]
  end

  def self.player_colours
    [ BLUE, RED, GREEN, YELLOW, BLACK ]
  end
end
