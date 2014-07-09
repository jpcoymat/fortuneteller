class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_user, :set_organization, :set_begin_and_end_dates, :set_product, :set_location
  
 
  def lookup
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @products = @organization.products
    @locations = @organization.locations 
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).where(product: @product).first
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
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => @begin_date, :projected_for.lte => @end_date).all
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
      @inventory_position = InventoryPosition.where(search_params).where(product: @product).first
      if @inventory_position
        @product_location_assignment = ProductLocationAssignment.where(product: @inventory_position.product, location: @inventory_position.location).first
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => @begin_date, :projected_for.lte => @end_date).all
      end
    end
  end
  

  private 
    
    def set_user
      @user = User.find(session[:user_id])
    end

    def set_organization
      @organization = User.find(session[:user_id]).organization
    end

    def search_params
      params.require(:inventory_position_search).permit(:location_id) 
    end
   
    def begin_date
      if params[:inventory_position_search].nil? or params[:inventory_position_search][:begin_date].blank?  
        @begin_date = Date.today 
      else
        @begin_date = Date.parse(params[:inventory_position_search][:begin_date])
      end
      @begin_date
    end

    def end_date
      if params[:inventory_position_search].nil? or params[:inventory_position_search][:end_date].blank? 
        @end_date = Date.today + (@user.organization.days_to_project - 1).days 
      else
        @end_date = Date.parse(params[:inventory_position_search][:end_date])
      end
      @end_date
    end

    def set_begin_and_end_dates
      begin_date
      end_date
    end

    def set_product
      if  params[:inventory_position_search].nil? or  params[:inventory_position_search][:product_name].blank?
        @product = nil
      else
        @product = Product.where(name: params[:inventory_position_search][:product_name]).first unless params[:inventory_position_search][:product_name].blank?
      end
      @product
    end

   def set_location
     if params[:inventory_position_search].nil? or  params[:inventory_position_search][:location_id].blank?
       @location = nil
     else
       @location = Location.find(params[:inventory_position_search][:location_id])
     end
     @location
   end


end
