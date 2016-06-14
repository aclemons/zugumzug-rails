class PlayersController < ApplicationController
  load_and_authorize_resource :game
  load_and_authorize_resource :through => :game, :id_param => :player_id

  def create
    @service = AddPlayer.new(@game, @player)

    call_service_and_respond(@service)
  end

  # DELETE /games/:game_id/players/:player_id/destination_tickets
  def discard_destination_tickets
    @service = DiscardDestinationTickets.new(
      @game,
      @player,
      (params.fetch(:destination_ids, []) || [])
    )

    call_service_and_respond(@service)
  end

  # PATCH /games/:game_id/players/:player_id/destination_tickets/assign
  def draw_destination_tickets
    @service = DrawDestinationTickets.new(@game, @player)

    call_service_and_respond(@service)
  end

  # PATCH /games/:game_id/players/:player_id/train_cards(/:train_card_id)
  def draw_train_card
    train_card_id = params.permit(:train_card_id).fetch(:train_card_id, nil)
    train_card_id = train_card_id.present? ? train_card_id.to_i : nil

    @service = DrawTrainCard.new(@game, @player, train_card_id)

    call_service_and_respond(@service)
  end

  # POST /games/:game_id/players/:player_id/routes/
  def build_route
    @service = BuildRoute.new(
      @game,
      @player,
      params.permit(:route_id).require(:route_id).to_i,
      (params.fetch(:train_card_ids, []) || [])
    )

    call_service_and_respond(@service)
  end

  private

  def create_params
    params.require(:player).permit(:name, :colour, :user_id)
  end

  def call_service_and_respond(service)
    if service.call
      respond_to do |format|
        format.html { redirect_to(service.game) }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html {
          @game.reload
          flash[:danger] = service.errors.keys.map { |k| "#{k}: #{service.errors[k].to_sentence}"}.to_sentence
          redirect_to(@game)
        }
        format.json { render json: service.errors, status: :bad_request }
      end
    end
  end
end
