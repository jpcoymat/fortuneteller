class GroupedProjectionsController < ApplicationController

  before_filter :authorize

  def index
    if projected_for(projection_search_params).nil?
      @inventory_positions = "Please provide a date parameter to complete your search"
    elsif product_array.empty? and location_array.empty?
      @inventory_positions = "Please enter either Product or Location search criteria"
    else
      @projection_date = projected_for(projection_search_params) 
      @inventory_positions = InventoryPosition.all
      @inventory_positions = @inventory_positions.in(product_id: product_array) unless product_array.empty?
      @inventory_positions = @inventory_positions.in(location_id: location_array) unless location_array.empty?
    end
  end

  def multi_product_location
    if projected_for(multi_product_location_params).nil?
      @inventory_positions = "Please provide a date parameter to complete your search"
    elsif multi_product_location_params["products"].empty? or multi_product_location_params["locations"].empty?
      @inventory_positions = "No Product or Location data provided"
    else
      @inventory_positions = InventoryPosition.in(product_id: multi_product_location_params["products"]).in(location_id: multi_product_location_params["locations"]) 
    end  
    render action: "index" 
  end


  protected

   def multi_product_location_params
     params.require('projection_search').permit(:products, :location, :projected_for)
   end

   def projection_search_params
     params.require('projection_search').permit(:product_name, :location_id, :location_group_id, :product_id, :product_category, :projected_for)
   end

   def projected_for(search_params)
     @projected_for = nil
     @projected_for = Date.parse(search_params["projected_for"]) unless search_params["projected_for"].blank?
     @projected_for
   end
   
   def product_array
     @product_array = []
     unless projection_search_params["product_category"].blank?
       @product_array = Product.where(product_category: projection_search_params["product_category"]).all.map {|product| product.id}
     end
     unless projection_search_params["product_name"].blank?
       @product_array = Product.where(name: projection_search_params["product_name"]).all.map {|product| product.id}
     end
     @product_array
   end
   

   def location_array
     @location_array = []
     unless projection_search_params["location_group_id"].blank?
       @location_array = Location.where(location_group_id: projection_search_params["location_group_id"]).all.map {|location| location.id}
     end
     @location_array << projection_search_params["location_id"] unless projection_search_params["location_id"].blank?
     @location_array
   end

   
end
