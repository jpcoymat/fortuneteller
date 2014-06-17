class InventoryExceptionsController < ApplicationController

  before_filter :authorize
  

  def index
    @inventory_exceptions = InventoryException.where(inventory_exception_params).order_by(:priority.asc, :begin_date.asc)
    @exception_durations = []
    @exception_days_to_impact = []
    @inventory_exceptions.each do |inventory_exception| 
      @exception_durations << inventory_exception.duration
      @exception_days_to_impact << inventory_exception.days_to_impact
    end
    @max_duration = @exception_durations.max
    @max_days_to_impact = @exception_days_to_impact.max
    @min_days_to_impact = [0, @exception_days_to_impact.min - 2].max 
    @color_increment = ((@max_days_to_impact - @min_days_to_impact)/3).floor
    @color_limits = {
		     "red_end" => @min_days_to_impact + @color_increment,
                     "yellow_end" => @min_days_to_impact + 2*@color_increment}
    @exception_colors = {}
    @inventory_exceptions.each do |inventory_exception|
      if inventory_exception.days_to_impact <= @color_limits["red_end"]
        @exception_colors[inventory_exception.id] = "red"
      elsif  inventory_exception.days_to_impact <= @color_limits["yellow_end"]
        @exception_colors[inventory_exception.id] = "yellow"
       else
         @exception_colors[inventory_exception.id] = "green"
      end
    end
  end

  protected
   
    def inventory_exception_params
      params.require(:inventory_exception).permit(:location_id, :product_id)
    end

end
