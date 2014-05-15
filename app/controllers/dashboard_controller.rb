class DashboardController < ApplicationController

  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    InventoryException.all.destroy
    InventoryPosition.all.each {|ip| ip.generate_inventory_exceptions}
    @locations = @user.organization.locations
    @data_array = [] 
    @locations.each do |location|
        @data_array << [location.latitude, location.longitude, location.name, location.inventory_exceptions.where(priority: 1).count, location.inventory_exceptions.where(priority: 2).count]
    end
  end


end
