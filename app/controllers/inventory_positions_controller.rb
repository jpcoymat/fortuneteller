class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_organization
  
 
  def lookup
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).where(product: product).first
      if @inventory_position
        @product_location_assignment = ProductLocationAssignment.where(product: @inventory_position.product, location: @inventory_position.location).first
        @data = []
        min_quantity = []
        on_hand_data = []
	on_order_data =[]
	in_transit_data = []
	allocated_data = []
	forecasted_data = []
	available_data = []
        max_quantity = []
        search_range_start = begin_date 
        search_range_end = end_date
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => search_range_start, :projected_for.lte => search_range_end).all
        @projections.each do |ip| 
          min_quantity << [ip.projected_for.to_formatted_s(:short),  @product_location_assignment.minimum_quantity]
	  on_hand_data << [ip.projected_for.to_formatted_s(:short), ip.on_hand_quantity]
          available_data << [ip.projected_for.to_formatted_s(:short), ip.available_quantity]
	  on_order_data << [ip.projected_for.to_formatted_s(:short), ip.on_order_quantity]
 	  in_transit_data << [ip.projected_for.to_formatted_s(:short), ip.in_transit_quantity]
	  allocated_data << [ip.projected_for.to_formatted_s(:short), ip.allocated_quantity]
	  forecasted_data << [ip.projected_for.to_formatted_s(:short), ip.forecasted_quantity]
          max_quantity << [ip.projected_for.to_formatted_s(:short), @product_location_assignment.maximum_quantity]
        end
        @data << {name: "Min", data: min_quantity}
        @data << {name: "On Hand", data: on_hand_data}
	@data << {name: "In Transit", data: in_transit_data}
	@data << {name: "On Order", data: on_order_data}
	@data << {name: "Allocated", data: allocated_data}
	@data << {name: "Planned Consumption", data: forecasted_data}
	@data << {name: "Available", data: available_data}
        @data << {name: "Max", data: max_quantity}
      end
      logger.debug "Data: " + @data.to_s	
    end
  end

  def stacked_view
    @user = User.find(session[:user_id])
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).where(product: product).first
      if @inventory_position
        @product_location_assignment = ProductLocationAssignment.where(product: @inventory_position.product, location: @inventory_position.location).first
        search_range_start = begin_date
        search_range_end = end_date
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => search_range_start, :projected_for.lte => search_range_end).all
      end
    end
  end
  

  private 
    def set_organization
      @organization = User.find(session[:user_id]).organization
    end

    def search_params
      params.require(:inventory_position_search).permit(:location_id) 
    end
   
    def begin_date
      params[:inventory_position_search][:begin_date].blank? ? @begin_date = Date.today : @begin_date = Date.parse(params[:inventory_position_search][:begin_date])
      @begin_date
    end

    def end_date
      params[:inventory_position_search][:end_date].blank? ? @end_date = Date.today + User.find(session[:user_id]).organization.days_to_project.days : @end_date = Date.parse(params[:inventory_position_search][:end_date])
      @end_date
    end

    def product
      @product = Product.where(name: params[:inventory_position_search][:product_name]).first unless params[:inventory_position_search][:product_name].blank?
    end


end
