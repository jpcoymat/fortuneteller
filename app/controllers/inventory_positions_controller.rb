class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_organization
   
  def lookup
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).first
      if @inventory_position
        @data = []
        on_hand_data = []
	on_order_data =[]
	in_transit_data = []
	allocated_data = []
	forecasted_data = []
	available_data = []
        @inventory_position.inventory_projections.each do |ip|
	  on_hand_data << [ip.projected_for.to_formatted_s(:short), ip.on_hand_quantity]
          available_data << [ip.projected_for.to_formatted_s(:short), ip.available_quantity]
	  on_order_data << [ip.projected_for.to_formatted_s(:short), ip.on_order_quantity]
 	  in_transit_data << [ip.projected_for.to_formatted_s(:short), ip.in_transit_quantity]
	  allocated_data << [ip.projected_for.to_formatted_s(:short), ip.allocated_quantity]
	  forecasted_data << [ip.projected_for.to_formatted_s(:short), ip.forecasted_quantity]
        end
        @data << {name: "On Hand Quantity", data: on_hand_data}
	@data << {name: "On Order Quantity", data: on_order_data}
	@data << {name: "In Transit Quantity", data: in_transit_data}
	@data << {name: "Allocated Quantity", data: allocated_data}
	@data << {name: "Available Quantity", data: available_data}
	@data << {name: "Forecasted Quantity", data: forecasted_data}
      end
    end
  end


  private 

    def set_organization
      @organization = User.find(session[:user_id]).organization
    end
   
    def inventory_position_params
      params.require(:inventory_position).permit(:product_id, :location_id)
    end

    def search_params
      params.require(:inventory_position_search).permit(:location_id, :product_id) 
    end

end
