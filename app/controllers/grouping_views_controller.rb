class GroupingViewsController < ApplicationController

  before_filter :authorize
  before_action :set_user, :set_product, :set_begin_and_end_dates, :set_location, :set_location_group, :set_product_category

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
        @dates, @projections, @min_qty, @on_hand, @on_order, @in_transit, @allocated, @forecasted, @available, @max_qty = [], [],[],[],[],[],[],[],[],[]
        current_search_date = @begin_date
        while current_search_date <= @end_date
          @dates << current_search_date
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
          @projections << {projected_for: current_search_date}
       	  @min_qty << min_quantity
          @on_hand << total_on_hand
          @available << total_available
          @on_order << total_on_order
 	  @in_transit << total_in_transit
	  @allocated << total_allocated
	  @forecasted << total_forecasted
	  @max_qty << max_quantity
          current_search_date += 1.day
        end
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
        @dates, @min_qty, @on_hand, @on_order, @in_transit, @allocated, @forecasted, @available, @max_qty = [], [], [], [], [], [], [], [], []
        while current_search_date <= @end_date
          @dates << current_search_date
          total_min, total_on_hand, total_on_order, total_in_transit, total_allocated, total_forecasted, total_available, total_max = 0,0,0,0,0,0,0,0
          @inventory_positions.each do |position|
            projection = position.inventory_projections.where(projected_for: current_search_date).first
            if projection
              total_min += position.product_location_assignment.minimum_quantity
              total_on_hand += projection.on_hand_quantity
              total_on_order += projection.on_order_quantity
              total_in_transit += projection.in_transit_quantity
              total_allocated +=  projection.allocated_quantity
              total_forecasted += projection.forecasted_quantity
              total_available += projection.available_quantity
              total_max += position.product_location_assignment.maximum_quantity
            end
          end
          @min_qty << total_min
          @on_hand << total_on_hand
          @available << total_available 
          @on_order << total_on_order
          @in_transit << total_in_transit
          @allocated << total_allocated
          @forecasted << total_forecasted
          @max_qty << total_max
          current_search_date += 1.day
        end
      end
    end
  end


  def inventory_bucket_view
    set_inventory_bucket
    @organization = @user.organization
    @location_groups = @organization.location_groups
    @products = @organization.products
    if request.post?
      @locations = Location.where(location_group: @location_group).all.entries
      @product_params_missing = (bucket_search_params["product_name"].blank? and bucket_search_params["product_category"].blank?)
      unless @locations.empty? or @product_params_missing
        @series = []
        @locations.each do |location|
          location_data = []
          @inventory_positions = inventory_positions_for_bucket_view(location)
          for current_date in (@begin_date .. @end_date)
            daily_quantity = 0
            @inventory_positions.each do |inventory_position|
              projection = inventory_position.inventory_projections.where(projected_for: current_date).first
              daily_quantity += projection.attributes[bucket_search_params["inventory_bucket"]] if projection
            end 
            location_data << daily_quantity
          end
          @series << {"location_name" => location.name, "data"=> location_data} 
        end
      end
    end
  end


  def multichoose_view
    @organization = @user.organization
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      if validate_multichoose_parameters > 0
        @inventory_positions = multichoose_inventory_positions
        if @inventory_positions.count >= 1
          current_search_date = @begin_date
          @min_qty, @on_hand, @on_order, @in_transit, @allocated, @forecasted, @available, @max_qty = [], [], [], [], [], [], [], []
          while current_search_date <= @end_date
            total_min, total_on_hand, total_on_order, total_in_transit, total_allocated, total_forecasted, total_available, total_max = 0,0,0,0,0,0,0,0
            @inventory_positions.each do |position|
              projection = position.inventory_projections.where(projected_for: current_search_date).first
              if projection
                total_min += position.product_location_assignment.minimum_quantity
                total_on_hand += projection.on_hand_quantity
                total_on_order += projection.on_order_quantity
                total_in_transit += projection.in_transit_quantity
                total_allocated +=  projection.allocated_quantity
                total_forecasted += projection.forecasted_quantity
                total_available += projection.available_quantity
                total_max += position.product_location_assignment.maximum_quantity
              end
            end
            @min_qty << total_min
            @on_hand << total_on_hand
            @available << total_available
            @on_order << total_on_order
            @in_transit << total_in_transit
            @allocated << total_allocated
            @forecasted << total_forecasted
            @max_qty << total_max
            current_search_date += 1.day
          end
        end      
      else
        @inventory_positions = "Invalid params " + validate_multichoose_parameters.to_s + " - " + multichoose_params.to_s
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
      @inventory_positions_for_location_centric = InventoryPosition.where(location: @location)
      products = products.where(product_category: @product_category) unless @product_category.blank?
      products = products.where(id: @product.id) if @product
      array_of_product_ids = []
      products.each {|product| array_of_product_ids << product.id}
      @inventory_positions_for_location_centric = @inventory_positions_for_location_centric.in(product_id: array_of_product_ids) if array_of_product_ids.count > 0
      @inventory_positions_for_location_centric
    end


    def inventory_positions_for_product_centric
      @inventory_positions_for_product_centric = "Please enter a Product Category or select a Product" 
      if product_search_params["product_name"].blank? and product_search_params["product_category"].blank?
        @inventory_positions_for_product_centric
      else
	prods = Product.where(organization: @user.organization)
        prods = prods.where(product_category: @product_category) unless @product_category.blank?
	prods = prods.where(id: @product.id) if @product
	locs = Location.where(organization: @user.organization)
	locs = locs.where(location_group: @location_group) if @location_group
	locs = locs.where(id: @location.id) if @location
	@inventory_positions_for_product_centric = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).in(location_id: locs.all.map {|loc| loc.id})
	@inventory_positions_for_product_centric
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

    def set_product
      if params[:group_search].nil? or  params[:group_search][:product_name].blank?
        @product = nil
      else
        @product = Product.where(name: params[:group_search][:product_name]).first 
      end
      @product
    end

   def set_inventory_bucket
     @inventory_bucket = nil
     if params[:group_search] and !(params[:group_search][:inventory_bucket].blank?)
       @inventory_bucket = params[:group_search][:inventory_bucket]
     end
     @inventory_bucket
   end

    def set_location
      @location = nil
      if params[:group_search] and params[:group_search].has_key?(:location_id) and !(params[:group_search][:location_id].blank?)
        @location = Location.find(params[:group_search][:location_id])
      end
      @location
    end

    def inventory_positions_for_bucket_view(location)
      prods = Product.where(organization: @user.organization)
      prods = prods.where(id: @product.id) if @product
      prods = prods.where(product_category: bucket_search_params["product_category"]) unless bucket_search_params["product_category"].blank?
      @inventory_positions_for_bucket_view = InventoryPosition.in(product_id: prods.all.map {|prod| prod.id}).where(location: location)
      @inventory_positions_for_bucket_view
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

   def set_location_group
     @location_group = nil
     if params[:group_search] and !(params[:group_search][:location_group_id].blank?)
       @location_group = LocationGroup.find(params[:group_search][:location_group_id]) 
     end
     @location_group
   end

   def set_product_category
     @product_category = ""
     if params[:group_search] and !(params[:group_search][:product_category].blank?)
       @product_category = params[:group_search][:product_category]
     end
     @product_category
   end

   def multichoose_params
     params.require(:group_search).permit(:locations, :products) 
   end 

   def validate_multichoose_parameters
     products = params[:group_search]["products"]
     if products.nil? 
       return -3
     elsif products.count == 1 and products[0] = ""
       return -1
     else
       locations = params[:group_search]["locations"]
       if locations.nil? or (locations.count == 1 and locations[0] = "")
         return -2
       else
         return 1
       end
     end
   end

   def multichoose_inventory_positions
     @input_products = params[:group_search]["products"]
     @input_locations = params[:group_search]["locations"]
     @multichoose_inventory_positions = InventoryPosition.in(product_id: @input_products).in(location_id: @input_locations)
     @multichoose_inventory_positions
   end

end
