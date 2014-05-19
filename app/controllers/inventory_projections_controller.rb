class InventoryProjectionsController < ApplicationController
  
  before_filter :authorize
  
  def show
    @inventory_position = InventoryPosition.find(params[:inventory_position_id])
    @inventory_projection = @inventory_position.inventory_projections.find(params[:id])
  end

  def index
  end

  protected
   
   def inventory_projetion_params
     params.require(:inventory_projection).permit(:product_id, :location_id, :product_category, :location_group_id)
   end


end

