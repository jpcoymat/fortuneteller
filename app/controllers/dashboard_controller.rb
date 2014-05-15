class DashboardController < ApplicationController

  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @data_array_string = ""
    @locations.each do |location|
        @data_array_string += "[" + location.latitude.to_s + ", " + location.longitude.to_s +  ", " + location.inventory_exceptions.count.to_s + ", " + location.name + "]"
        @data_array_string += "," unless @locations.last == location			
    end
  end


end
