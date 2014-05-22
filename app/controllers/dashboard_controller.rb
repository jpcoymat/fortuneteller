class DashboardController < ApplicationController

  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @location_groups = @user.organization.location_groups
    @data_array = [] 
    @locations.each do |location|
        @data_array << {"lat" => location.latitude, 
		        "long" => location.longitude, 
                        "name" => location.name, 
                        "p1" => location.inventory_exceptions.where(priority: 1).count, 
                        "p2" => location.inventory_exceptions.where(priority: 2).count
                       }
    end
  end


end
