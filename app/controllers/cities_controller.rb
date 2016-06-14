class CitiesController < ApplicationController
  skip_before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    return unless @cities = apply_filters(@cities, filtering_params)

    @cities = @cities.order('name ASC')

    respond_to do |format|
      format.json
    end
  end

  def show
    respond_to do |format|
      format.json
      format.html
    end
  end

  private

  def filtering_params
    params.slice(:name)
  end
end
