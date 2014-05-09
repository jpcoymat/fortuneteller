class MainController < ApplicationController
  
  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @map_data = [["City","On Hand Quantity"]]
    @locations.each do |location|
       @map_data << [location.latitute, location.longitude, location.aggregate_quantity("on_hand_quantity"), location.city]
    end
    @map_options = {"region" => "us_metro", "dataMode" => "markers"}
  end


end

