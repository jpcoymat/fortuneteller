class InventoryExceptionsController < ApplicationController

  before_filter :authorize
  

  def index
    @inventory_exceptions = InventoryException.where(inventory_exception_params)
  end

  protected
   
    def inventory_exception_params
      params.require(:inventory_exception).permit(:location_id, :product_id)
    end

end
