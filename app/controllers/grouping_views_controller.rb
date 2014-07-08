class GroupingViewsController < ApplicationController

  before_filter :authorize
  before_action :set_user, :set_selected_product, :set_begin_and_end_dates

  def product_centric
    @organization = @user.organization 
    @locations = @organization.locations
    @products =  @organization.products
    @location_groups = @organization.location_groups
    if request.post? 	
      @clean_search_hash = clean_product_search_params 
      @inventory_positions = inventory_positions_for_product_centric
      if @inventory_positions.class != String and @inventory_positions.count > 0
        @search_criteria_to_string = search_criteria_to_string(@clean_search_hash.merge({"begin_date" => @begin_date, "end_date" => @end_date}))
        @data = []
        @inventory_hash = {}
        min_quantity_data = []
        on_hand_data = []
        on_order_data =[]
        in_transit_data = []
        allocated_data = []
        forecasted_data = []
        available_data = []
        max_quantity_data = []
        current_search_date = @begin_date
        while current_search_date <= @end_date
          min_quantity, total_on_hand, total_on_order, total_in_transit, total_allocated, total_forecasted, total_available, max_quantity = 0,0,0,0,0,0,0,0
          @inventory_positions.each do |position|
            projection = position.inventory_projections.where(projected_for: current_search_date).first
            if projection
              min_quantity += position.product_location_assignment.minimum_quantity
              total_on_hand += projection.on_hand_quantity
              total_on_order += projection.on_order_quantity
              total_in_transit += projection.in_transit_quantity
              total_allocated +=  projection.allocated_quantity
              total_forecasted += projection.forecasted_quantity
              total_available += projection.available_quantity
              max_quantity += position.product_location_assignment.maximum_quantity
            end
          end
          @inventory_hash[current_search_date.to_formatted_s(:short)] = {"min_quantity" => min_quantity,
                                                                        "on_hand_quantity"   => total_on_hand,
                                                                        "on_order_quantity"   => total_on_order,
                                                                        "in_transit_quantity" => total_in_transit,
                                                                        "allocated_quantity"  => total_allocated,
                                                                        "forecasted_quantity"  => total_forecasted,
                                                                        "available_quantity"  => total_available,
                                                                        "max_quantity" => max_quantity
                                                                        }
          min_quantity_data << [current_search_date.to_formatted_s(:short), min_quantity] 
          on_hand_data << [current_search_date.to_formatted_s(:short), total_on_hand]
          on_order_data << [current_search_date.to_formatted_s(:short), total_on_order]
          in_transit_data << [current_search_date.to_formatted_s(:short), total_in_transit]
          allocated_data << [current_search_date.to_formatted_s(:short), total_allocated]
          forecasted_data << [current_search_date.to_formatted_s(:short), total_forecasted]
          available_data << [current_search_date.to_formatted_s(:short), total_available]
          max_quantity_data << [current_search_date.to_formatted_s(:short),max_quantity]
          current_search_date += 1.day
        end
        @data << {name: "Min", data: min_quantity_data}
        @data << {name: "On Hand", data: on_hand_data}
        @data << {name: "In Transit", data: in_transit_data}
        @data << {name: "On Order", data: on_order_data}
        @data << {name: "Allocated", data: allocated_data}
        @data << {name: "Planned Consumption", data: forecasted_data}
        @data << {name: "Available", data: available_data}
        @data << {name: "Max", data: max_quantity_data}
      end
    end
    
  end

  def location_centric
    @organization = @user.organization
    @locations = @organization.locations
    @products =  @organization.products
    if request.post?
      @clean_search_hash = clean_location_search_params
      @inventory_positions = inventory_positions_for_location_centric
      if @inventory_positions.count > 0
        current_search_date = @begin_date
        @search_criteria_to_string = search_criteria_to_string(@clean_search_hash.merge({"begin_date" => @begin_date, "end_date" => @end_date}))
	@data = []
	@inventory_hash = {}
        on_hand_data = []
        on_order_data =[]
        in_transit_data = []
        allocated_data = []
        forecasted_data = []
        available_data = []        
        while current_search_date <= @end_date
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
    @organization = @user.organization
    @location_groups = @organization.location_groups
    @products = @organization.products
    if request.post?
      @locations = Location.where(location_group_id: bucket_search_params["location_group_id"])
      @product_params_missing = (bucket_search_params["product_name"].blank? and bucket_search_params["product_category"].blank?)
      unless @locations.empty? or @product_params_missing
        current_date = @begin_date 
        @data = []
        @series_hash = {}
        @locations.each do |location|
          location_data =[]
          @inventory_positions = inventory_positions_for_bucket_view(location)
          if @inventory_positions.count > 0
            while current_date <= @end_date
              bucket_quantity = 0
              @inventory_positions.each do |position|
                projection = position.inventory_projections.where(projected_for: current_date).first
                bucket_quantity += projection.attributes[bucket_search_params["inventory_bucket"]] if projection
              end
              location_data << [current_date.to_formatted_s(:short), bucket_quantity]
              current_date += 1.day
            end  
            @series_hash[@data.count] = {type: "line",  pointSize: 0}          
            @data << {name: location.name, data: location_data}
          end
        end
      end
    end
  end


  protected
    
    def set_user
      @user = User.find(session[:user_id])
    end

    def location_search_params
      params.require(:group_search).permit(:product_name, :product_category, :location_id)
    end

    def clean_location_search_params
      @clean_location_search_params = {}
      location_search_params.each {|k,v| @clean_location_search_params[k] = v unless v.blank?}
      @clean_location_search_params
    end

    def product_search_params
      params.require(:group_search).permit(:product_name, :product_category, :location_id, :location_group_id)
    end

    def clean_product_search_params
      @clean_product_search_params ={}
      product_search_params.each {|k,v| @clean_product_search_params[k] = v unless v.blank?}
      @clean_product_search_params
    end

    def bucket_search_params
      params.require(:group_search).permit(:product_name, :product_category, :inventory_bucket, :location_group_id)
    end

    def inventory_positions_for_location_centric
      products = Product.where(organization: @user.organization)
      @inventory_positions_for_location_centric = InventoryPosition.where(location_id: location_search_params["location_id"])
      products = products.where(product_category: location_search_params["product_category"]) unless location_search_params["product_category"].blank?
      products = products.where(name: location_search_params["product_name"]) unless location_search_params["product_id"].blank?
      array_of_product_ids = []
      products.each {|product| array_of_product_ids << product.id}
      @inventory_positions_for_location_centric = @inventory_positions_for_location_centric.in(product_id: array_of_product_ids) if array_of_product_ids.count > 0
      @inventory_positions_for_location_centric
    end


    def inventory_positions_for_product_centric
      @inventory_positions_for_product_centric = "Please enter a Product Category or select a Product" 
      if product_search_params["product_name"].blank? and product_search_params["product_category"].blank?
        return @inventory_positions_for_product_centric
      else
	prods = Product.where(organization: @user.organization)
        prods = prods.where(product_category: product_search_params["product_category"]) unless product_search_params["product_category"].blank?
	prods = prods.where(name: product_search_params["product_name"]) unless product_search_params["product_name"].blank?
	locs = Location.where(organization: @user.organization)
	locs = locs.where(location_group_id: product_search_params["location_group_id"]) unless product_search_params["location_group_id"].blank?
	locs = locs.where(id: product_search_params["location_id"]) unless product_search_params["location_id"].blank?
	@inventory_positions_for_product_centric = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).in(location_id: locs.all.map {|loc| loc.id})
	return @inventory_positions_for_product_centric
      end
    end


    def begin_date
      if params[:group_search].nil? or params[:group_search][:begin_date].blank?
        @begin_date = Date.today 
      else
        @begin_date = Date.parse(params[:group_search][:begin_date])
      end
      @begin_date
    end

    def end_date
      if params[:group_search].nil? or params[:group_search][:end_date].blank?
        @end_date = Date.today + (@user.organization.days_to_project - 1).days
      else
        @end_date = Date.parse(params[:group_search][:end_date])
      end
      @end_date
    end

    def set_begin_and_end_dates
      begin_date
      end_date
    end


    def set_selected_product
      params[:group_search] ? @selected_product =  params[:group_search][:product_name] : @selected_product = ""
      @selected_product
    end

    def inventory_positions_for_bucket_view(location)
      prods = Product.where(organization: @user.organization)
      prods = prods.where(name: bucket_search_params["product_name"]) unless bucket_search_params["product_name"].blank?
      prods = prods.where(product_category: bucket_search_params["product_category"]) unless bucket_search_params["product_category"].blank?
      @inventory_positions_for_bucket_view = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).where(location: location)
      @inventory_positions_for_bucket_view
    end



    def last_projection_date(inventory_positions)
      @last_projection_date = inventory_positions.first.inventory_projections.last.projected_for
    end

    def search_criteria_to_string(search_criteria)
      @search_criteria_to_string = ""
      search_criteria.each do |k,v|
        @search_criteria_to_string += k.to_s.humanize + ": "
        if k.to_s.include?("_id") 
          class_name_to_string = k.gsub("_id","").classify
          @search_criteria_to_string += eval class_name_to_string + ".find(\"" + v.to_s +  "\").try(:name)"
        else
          @search_criteria_to_string += v.to_s
        end
         @search_criteria_to_string += " "
      end 
      @search_criteria_to_string
    end


end
