class MainController < ApplicationController
  
  before_filter :authorize

  def index
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @data_array_string = ""
    @quantities = []
    @locations.each do |location|
        qty = location.aggregate_quantity("on_hand_quantity")
        @quantities << qty
        @data_array_string += ",[" + location.latitude.to_s + ", " + location.longitude.to_s +  ", "  + qty.to_s + "]"
    end
    @max_quantity = (@quantities.max*1.1).to_i
  end


end

