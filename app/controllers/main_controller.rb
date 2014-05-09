class MainController < ApplicationController
  
  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @map_data = []
    @locations.each do |location|
       @map_data << [location.city, location.aggregate_quantity("on_hand_quantity")]
    end
  end


end

