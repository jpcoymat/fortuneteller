class DashboardController < ApplicationController

  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @data_array = [] 
    @locations.each do |location|
        @data_array << [location.latitude, location.longitude, location.inventory_exceptions.count, "'" + location.name + "'"]
    end
  end


end
