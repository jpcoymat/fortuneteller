class GroupingViewsController < ApplicationController

  before_filter :authorize
  before_action :set_user

  def product_centric
    @locations = @user.organization.locations
    @products =  @user.organization.products
    @location_groups = @user.organization.location_groups
    if request.post? 	
      @inventory_positions = inventory_positions_for_product_centric
      if @inventory_positions.class != String and @inventory_positions.count > 0
        current_search_date = product_begin_date
        end_search_date = product_end_date(@inventory_positions)
        @data = []
        @inventory_hash = {}
        on_hand_data = []
        on_order_data =[]
        in_transit_data = []
        allocated_data = []
        forecasted_data = []
        available_data = []
        while current_search_date <= end_search_date
          total_on_hand, total_on_order, total_in_transit, total_allocated, total_forecasted, total_available = 0,0,0,0,0,0
          @inventory_positions.each do |position|
            projection = position.inventory_projections.where(projected_for: current_search_date).first
            if projection
              total_on_hand += projection.on_hand_quantity
              total_on_order += projection.on_order_quantity
              total_in_transit += projection.in_transit_quantity
              total_allocated +=  projection.allocated_quantity
              total_forecasted += projection.forecasted_quantity
              total_available += projection.available_quantity
            end
          end
          @inventory_hash[current_search_date.to_formatted_s(:short)] = {"on_hand_quantity"   => total_on_hand,
                                                                        "on_order_quantity"   => total_on_order,
                                                                        "in_transit_quantity" => total_in_transit,
                                                                        "allocated_quantity"  => total_allocated,
                                                                        "forcasted_quantity"  => total_forecasted,
                                                                        "available_quantity"  => total_available
                                                                        }
          on_hand_data << [current_search_date.to_formatted_s(:short), total_on_hand]
          on_order_data << [current_search_date.to_formatted_s(:short), total_on_order]
          in_transit_data << [current_search_date.to_formatted_s(:short), total_in_transit]
          allocated_data << [current_search_date.to_formatted_s(:short), total_allocated]
          forecasted_data << [current_search_date.to_formatted_s(:short), total_forecasted]
          available_data << [current_search_date.to_formatted_s(:short), total_available]
          current_search_date += 1.day
        end
        @data << {name: "On Hand", data: on_hand_data}
        @data << {name: "In Transit", data: in_transit_data}
        @data << {name: "On Order", data: on_order_data}
        @data << {name: "Allocated", data: allocated_data}
        @data << {name: "Planned Consumption", data: forecasted_data}
        @data << {name: "Available", data: available_data}
      end
    end
    
  end

  def location_centric
    @locations = @user.organization.locations
    @products =  @user.organization.products
    if request.post?
      @inventory_positions = inventory_positions_for_location_centric
      if @inventory_positions.count > 0
        current_search_date = begin_date
        end_search_date = end_date(@inventory_positions)
	@data = []
	@inventory_hash = {}
        on_hand_data = []
        on_order_data =[]
        in_transit_data = []
        allocated_data = []
        forecasted_data = []
        available_data = []        
        while current_search_date <= end_search_date
          total_on_hand, total_on_order, total_in_transit, total_allocated, total_forecasted, total_available = 0,0,0,0,0,0
          @inventory_positions.each do |position|
	    projection = position.inventory_projections.where(projected_for: current_search_date).first
	    if projection
              total_on_hand += projection.on_hand_quantity
	      total_on_order += projection.on_order_quantity
	      total_in_transit += projection.in_transit_quantity
	      total_allocated +=  projection.allocated_quantity
	      total_forecasted += projection.forecasted_quantity
              total_available += projection.available_quantity
	    end
          end 
	  @inventory_hash[current_search_date.to_formatted_s(:short)] = {"on_hand_quantity"   => total_on_hand,
									"on_order_quantity"   => total_on_order,
									"in_transit_quantity" => total_in_transit,
									"allocated_quantity"  => total_allocated,
									"forcasted_quantity"  => total_forecasted,
									"available_quantity"  => total_available
									}
	  on_hand_data << [current_search_date.to_formatted_s(:short), total_on_hand]
          on_order_data << [current_search_date.to_formatted_s(:short), total_on_order]
          in_transit_data << [current_search_date.to_formatted_s(:short), total_in_transit]
          allocated_data << [current_search_date.to_formatted_s(:short), total_allocated]
          forecasted_data << [current_search_date.to_formatted_s(:short), total_forecasted]
          available_data << [current_search_date.to_formatted_s(:short), total_available]
          current_search_date += 1.day
        end
        @data << {name: "On Hand", data: on_hand_data}
        @data << {name: "In Transit", data: in_transit_data}
        @data << {name: "On Order", data: on_order_data}
        @data << {name: "Allocated", data: allocated_data}
        @data << {name: "Planned Consumption", data: forecasted_data}
        @data << {name: "Available", data: available_data}
      end      
    end
  end

  def inventory_bucket_view
    @location_groups = LocationGroup.where(organization: @user.organization)
    @products = @user.organization.products
    if request.post?
      @locations = Location.where(location_group_id: bucket_search_params["location_group_id"])
      @product_params_missing = (bucket_search_params["product_id"].blank? and bucket_search_params["product_category"].blank?)
      unless @locations.empty? or @product_params_missing
        proj_start_date = bucket_begin_date
        logger.info "Start Date: " + proj_start_date.to_s
        proj_stop_date = bucket_end_date([InventoryPosition.where(location: @locations.first).first])
        logger.info "End Date: " + proj_stop_date.to_s
        @data = []
        @series_hash = {}
        @locations.each do |location|
          logger.info "Now adding trend line for location " + location.name 
          location_data =[]
          @inventory_positions = inventory_positions_for_bucket_view(location)
          if @inventory_positions.count > 0
            logger.info "Debug - Position Count For location " + location.name + ": " + @inventory_positions.all.count.to_s
            current_date = proj_start_date  
            while current_date <= proj_stop_date
	      logger.info "Finding projections for date " + current_date.to_s 
              bucket_quantity = 0
	      logger.info "Point 1"
              @inventory_positions.each do |position|
                logger.info "Point 2"
                projection = position.inventory_projections.where(projected_for: current_date).first
                logger.info "Point 3"
                bucket_quantity += projection.attributes[bucket_search_params["inventory_bucket"]] if projection
              end
              logger.info "Point 4"
              location_data << [current_date.to_formatted_s(:short), bucket_quantity]
              logger.info "Point 5"
              current_date += 1.day
            end  
            logger.info "Point 6"
            @series_hash[@data.count] = {type: "line",  pointSize: 0}
            logger.info "Point 7"
            @data << {name: location.name, data: location_data}
          end
        end
        logger.info "Debug - Data: " + @data.to_s
      end
    end
  end


  protected
    
    def set_user
      @user = User.find(session[:user_id])
    end

    def location_search_params
      params.require(:location_search).permit(:product_id, :product_category, :location_id)
    end

    def product_search_params
      params.require(:product_search).permit(:product_id, :product_category, :location_id, :location_group_id)
    end

    def bucket_search_params
      params.require(:bucket_search).permit(:product_id, :product_category, :inventory_bucket, :location_group_id)
    end

    def aggregate_daily_inventory_bucket(location, projection_date, inventory_bucket)
    end


    def inventory_positions_for_location_centric
      products = Product.where(organization: @user.organization)
      @inventory_positions_for_location_centric = InventoryPosition.where(location_id: location_search_params["location_id"])
      logger.info "Debug: " + location_search_params.to_s
      products = products.where(product_category: location_search_params["product_category"]) unless location_search_params["product_category"].blank?
      products = products.where(id: location_search_params["product_id"]) unless location_search_params["product_id"].blank?
      array_of_product_ids = []
      products.each {|product| array_of_product_ids << product.id}
      logger.info "Debug " + array_of_product_ids.to_s
      @inventory_positions_for_location_centric = @inventory_positions_for_location_centric.in(product_id: array_of_product_ids) if array_of_product_ids.count > 0
      @inventory_positions_for_location_centric
    end


    def inventory_positions_for_product_centric
      prods = Product.where(organization: @user.organization)
      @inventory_positions_for_product_centric = "Please enter a Product Category or select a Product" 
      if product_search_params["product_id"].blank? and product_search_params["product_category"].blank?
        return @inventory_positions_for_product_centric
      else
	logger.info "Debug: " + product_search_params.to_s
	prods = Product.where(organization: @user.organization)
        prods = prods.where(product_category: product_search_params["product_category"]) unless product_search_params["product_category"].blank?
	prods = prods.where(id: product_search_params["product_id"]) unless product_search_params["product_id"].blank?
	locs = Location.where(organization: @user.organization)
	locs = locs.where(location_group_id: product_search_params["location_group_id"]) unless product_search_params["location_group_id"].blank?
	locs = locs.where(id: product_search_params["location_id"]) unless product_search_params["location_id"].blank?
	@inventory_positions_for_product_centric = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).in(location_id: locs.all.map {|loc| loc.id})
	return @inventory_positions_for_product_centric
      end
    end


    def begin_date
      today = Date.today
      submitted_date = Date.today - 1.day
      unless params[:location_search]["begin_date(1i)"].blank? or params[:location_search]["begin_date(2i)"].blank? or params[:location_search]["begin_date(3i)"].blank?
        submitted_date = Date.new(params[:location_search]["begin_date(1i)"].to_i, params[:location_search]["begin_date(2i)"].to_i, params[:location_search]["begin_date(3i)"].to_i)
      end
      begin_date = [today, submitted_date].max
      begin_date
    end

    def end_date(inventory_positions)
      end_date = nil
      unless params[:location_search]["end_date(1i)"].blank? or params[:location_search]["end_date(2i)"].blank? or params[:location_search]["end_date(3i)"].blank?
        end_date = Date.new(params[:location_search]["end_date(1i)"].to_i, params[:location_search]["end_date(2i)"].to_i, params[:location_search]["end_date(3i)"].to_i)
      else
        end_date = last_projection_date(inventory_positions)
      end
      end_date
    end

    def product_begin_date
      today = Date.today
      submitted_date = Date.today - 1.day
      unless params[:product_search]["begin_date(1i)"].blank? or params[:product_search]["begin_date(2i)"].blank? or params[:product_search]["begin_date(3i)"].blank?
        submitted_date = Date.new(params[:product_search]["begin_date(1i)"].to_i, params[:product_search]["begin_date(2i)"].to_i, params[:product_search]["begin_date(3i)"].to_i)
      end
      begin_date = [today, submitted_date].max
      begin_date
    end

    def product_end_date(inventory_positions)
      end_date = nil
      unless params[:product_search]["end_date(1i)"].blank? or params[:product_search]["end_date(2i)"].blank? or params[:product_search]["end_date(3i)"].blank?
        end_date = Date.new(params[:product_search]["end_date(1i)"].to_i, params[:product_search]["end_date(2i)"].to_i, params[:product_search]["end_date(3i)"].to_i)
      else
        end_date = last_projection_date(inventory_positions)
      end
      end_date
    end

    def bucket_begin_date
      today = Date.today
      submitted_date = Date.today - 1.day
      unless params[:bucket_search]["begin_date(1i)"].blank? or params[:bucket_search]["begin_date(2i)"].blank? or params[:bucket_search]["begin_date(3i)"].blank?
        submitted_date = Date.new(params[:bucket_search]["begin_date(1i)"].to_i, params[:bucket_search]["begin_date(2i)"].to_i, params[:bucket_search]["begin_date(3i)"].to_i)
      end
      begin_date = [today, submitted_date].max
      begin_date
    end

    def bucket_end_date(inventory_positions)
      end_date = nil
      unless params[:bucket_search]["end_date(1i)"].blank? or params[:bucket_search]["end_date(2i)"].blank? or params[:bucket_search]["end_date(3i)"].blank?
        end_date = Date.new(params[:bucket_search]["end_date(1i)"].to_i, params[:bucket_search]["end_date(2i)"].to_i, params[:bucket_search]["end_date(3i)"].to_i)
      else
        end_date = last_projection_date(inventory_positions)
      end
      end_date
    end

    def inventory_positions_for_bucket_view(location)
      prods = Product.where(organization: @user.organization)
      prods = prods.where(id: bucket_search_params["product_id"]) unless bucket_search_params["product_id"].blank?
      prods = prods.where(product_category: bucket_search_params["product_category"]) unless bucket_search_params["product_category"].blank?
      @inventory_positions_for_bucket_view = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).where(location: location)
      @inventory_positions_for_bucket_view
    end


    def last_projection_date(inventory_positions)
      @last_projection_date = inventory_positions.first.inventory_projections.last.projected_for
    end


end
