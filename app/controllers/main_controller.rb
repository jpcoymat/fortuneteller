class MainController < ApplicationController
  
  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @map_data = [["City","On Hand Quantity"]]
    @locations.each do |location|
       @map_data << [location.geomap_data, location.aggregate_quantity("on_hand_quantity")]
    end
    @map_options = {"region" => "us_metro", "dataMode" => "markers"}
  end


end

