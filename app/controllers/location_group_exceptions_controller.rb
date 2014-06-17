class LocationGroupExceptionsController < ApplicationController

  before_filter :authorize


  def index
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @location_group_exceptions = LocationGroupException.where(location_group_exception_params).order_by(:begin_date.asc)

    @exception_durations = []
    @exception_days_to_impact = []
    @location_group_exceptions.each do |location_group_exception|
      @exception_durations << location_group_exception.duration
      @exception_days_to_impact << location_group_exception.days_to_impact
    end
    @max_duration = @exception_durations.max
    @max_days_to_impact = @exception_days_to_impact.max
    @min_days_to_impact = 0 
    @color_increment = ((@max_days_to_impact - @min_days_to_impact)/3).floor
    @color_limits = {
                     "red_end" => @min_days_to_impact + @color_increment,
                     "yellow_end" => @min_days_to_impact + 2*@color_increment}
    @exception_colors = {}
    @location_group_exceptions.each do |location_group_exception|
      if location_group_exception.days_to_impact <= @color_limits["red_end"]
        @exception_colors[location_group_exception.id] = "red"
      elsif  location_group_exception.days_to_impact <= @color_limits["yellow_end"]
        @exception_colors[location_group_exception.id] = "yellow"
       else
         @exception_colors[location_group_exception.id] = "green"
      end
    end


  end

  protected
   
    def location_group_exception_params
      params.require('location_group_exception').permit(:location_group_id)
    end



end
