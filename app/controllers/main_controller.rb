class MainController < ApplicationController
  
  before_filter :authenticate_user

  def index
    @user = User.find(session[:params])
  end


end

