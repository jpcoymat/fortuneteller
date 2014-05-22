class LocationGroupExceptionsController < ApplicationController

  before_filter :authorize


  def index
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @location_group_exceptions = @organizaion.location_group_exceptions
  end


end
