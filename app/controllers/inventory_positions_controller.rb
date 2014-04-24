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
        @inventory_position.inventory_projections.each do |ip|
          @data << [ip.projected_for.to_s, ip.available_quantity]
        end
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
