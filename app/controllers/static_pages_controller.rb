class StaticPagesController < ApplicationController
  skip_before_filter :authenticate_user!

  def home
  end

  def help
  end

  def about
  end
end
