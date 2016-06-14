class TrainCard < ActiveRecord::Base
  validates_inclusion_of :colour, :in => Colour::train_card_colours

  def locomotive?
    colour == Colour::NONE
  end
end
