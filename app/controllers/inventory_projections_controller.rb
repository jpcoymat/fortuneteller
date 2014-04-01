class InventoryProjectionsController < ApplicationController
  
  before_filter :authorize
  
  def show
    @inventory_position = InventoryPosition.find(params[:inventory_position_id])
    @inventory_projection = @inventory_position.inventory_projections.find(params[:id])
  end


end

