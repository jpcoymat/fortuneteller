class InventoryProjectionsController < ApplicationController
  
  before_filter :authorize
  
  def show
    @inventory_position = InventoryPosition.find(params[:inventory_position_id])
    @inventory_projection = @inventory_position.inventory_projections.find(params[:id])
  end

  protected
   
   def inventory_projetion_params
     params.require(:inventory_projection).permit(:product_id, :location_id, :product_category, :location_group_id)
   end

   def projected_for
     @projected_for = nil
     unless params[:projection_search]["projected_for(1i)"].blank? or params[:projection_search]["projected_for(2i)"].blank? or params[:projection_search]["projected_for(3i)"].blank?
       submitted_date = Date.new(params[:projection_search]["projected_for(1i)"].to_i, params[:projection_search]["projected_for(2i)"].to_i, params[:projection_search]["projected_for(3i)"].to_i)
     end
     @projected_for
    end


end

