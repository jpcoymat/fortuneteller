class InventoryExceptionsController < ApplicationController

  before_filter :authorize
  

  def index
    @inventory_exceptions = InventoryException.where(inventory_exception_params)
    @exception_durations = []
    @inventory_exceptions.each {|inventory_exception| @exception_durations << inventory_exception.duration}
    @max_duration = @exception_durations.max
  end

  protected
   
    def inventory_exception_params
      params.require(:inventory_exception).permit(:location_id, :product_id)
    end

end
