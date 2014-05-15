class InventoryExceptionController < ApplicationController

  before_filter :authorize
  

  def index
  end

  protected
   
   def inventory_exception_params
     params.require(:inventory_exception).permit(:location_id, :product_id):
   end


end
