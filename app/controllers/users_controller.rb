class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    return unless @users = apply_filters(@users, filtering_params)

    @users = @users.paginate(page: params[:page]).order('id ASC')

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

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def filtering_params
    params.slice(:email, :name)
  end
end
