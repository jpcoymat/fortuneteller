class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_organization
   
  def lookup
    @user = User.find(session[:user_id])
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).first
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
        search_range_start = begin_date || Date.today 
        search_range_end = end_date || search_range_start + @user.organization.days_to_project.days
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
   
    def begin_date
      @begin_date = nil
      submitted_date = Date.today - 1.day
      unless params[:inventory_position_search]["begin_date(1i)"].blank? or params[:inventory_position_search]["begin_date(2i)"].blank? or params[:inventory_position_search]["begin_date(3i)"].blank?
        submitted_date = Date.new(params[:inventory_position_search]["begin_date(1i)"].to_i, params[:inventory_position_search]["begin_date(2i)"].to_i, params[:inventory_position_search]["begin_date(3i)"].to_i)
      end
      @begin_date = submitted_date if submitted_date >= Date.today
      @begin_date
    end

    def end_date
      end_date = nil
      unless params[:inventory_position_search]["end_date(1i)"].blank? or params[:inventory_position_search]["end_date(2i)"].blank? or params[:inventory_position_search]["end_date(3i)"].blank?
        end_date = Date.new(params[:inventory_position_search]["end_date(1i)"].to_i, params[:inventory_position_search]["end_date(2i)"].to_i, params[:inventory_position_search]["end_date(3i)"].to_i)
      end
      end_date
    end



end
