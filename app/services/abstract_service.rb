class AbstractService
  extend ActiveModel::Translation
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods
  include GamePolicy

  attr_reader :errors, :game, :player

  def initialize(game, player)
    @game = game
    @player = player
    # errors on a PORO
    # per documentation at http://api.rubyonrails.org/classes/ActiveModel/Errors.html
    @errors = ActiveModel::Errors.new(self)
  end

  def read_attribute_for_validation(attr)
    send(attr)
  end

  def operation
    self.model_name.human
  end

  def allowed_phases
    raise NotImplementedError
  end

  def allowed_turn_states
    raise NotImplementedError
  end

  protected

  attr_writer :game

  def update_game
    service_operation = Proc.new do
      # refresh player after locking game
      player.reload unless player.nil? || player.id.nil?

      unless enforce_game_policy(game, player, self, self)
        raise ActiveRecord::Rollback
      end

      unless yield
        raise ActiveRecord::Rollback
      end

      EndGame.new().check_for_end_of_game(game, save_object_callback)

      true
    end

    if game
      game.with_lock(true, &service_operation)
    else
      Game.transaction(&service_operation)
    end
  end

  def save_object(object)
    unless object && object.save
      copy_errors(object)
      raise ActiveRecord::Rollback
    end
  end

  def copy_errors(source)
    source.errors.each { |attribute, error| errors.add(attribute, error) } if source
  end

  def save_object_callback
    Proc.new do |object|
      save_object(object)
    end
  end
end
