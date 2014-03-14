class MainController < ApplicationController
  
  before_filter :authorize

  def index
    @user = User.find(session[:params])
  end


end

