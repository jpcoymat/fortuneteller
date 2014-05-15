class DashboardController < ApplicationController

  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    InventoryException.all.destroy
    InventoryPosition.all.each {|ip| ip.generate_inventory_exceptions}
    @locations = @user.organization.locations
    @data_array = "" 
    @locations.each do |location|
        @data_array += ",[" + location.latitude.to_s + ", " + location.longitude.to_s + ", " + location.inventory_exceptions.count.to_s + "]"
    end
  end


end
