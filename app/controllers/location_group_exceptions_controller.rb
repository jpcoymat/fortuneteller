class LocationGroupExceptionsController < ApplicationController

  before_filter :authorize


  def index
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @location_group_exceptions = LocationGroupException.where(location_group_exception_params)
  end

  protected
   
    def location_group_exception_params
      params.require('location_group_exception').permit(:location_group_id)
    end



end
