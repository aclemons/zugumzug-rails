class GamesController < ApplicationController
  load_resource :except => [ :create ]
  authorize_resource :only => [ :index, :show, :update ]

  def index
    return unless @games = apply_filters(@games, filtering_params)

    @games = @games.paginate(page: params[:page]).order('id ASC')

    respond_to do |format|
      format.html
      format.json
    end
  end

  def show
    if !@game.setup_phase? && !@game.users_turn?(current_user) && !@game.over?
      @refresh_game = true
    end

    respond_to do |format|
      format.html
      format.json
    end
  end

  def new
  end

  def create
    service = CreateGame.new()

    call_service_and_respond(service, true)
  end

  def update
    service = StartGame.new(@game)

    call_service_and_respond(service)
  end

  private

  def filtering_params
    params.slice(:phase)
  end

  def call_service_and_respond(service, create=false)
    if service.call
      @game = service.game if create

      respond_to do |format|
        format.html { redirect_to(service.game) }
        format.json do
          if create
            render :show, status: :created, location: game_url(service.game)
          else
            head :no_content
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:danger] = service.errors.keys.map { |k| "#{k}: #{service.errors[k].to_sentence}"}.to_sentence

          if create
            render :new
          else
            @game.reload
            redirect_to(@game)
          end
        end
        format.json { render json: service.errors, status: :bad_request }
      end
    end
  end
end
