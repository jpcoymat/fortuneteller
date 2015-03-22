class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_user, :set_organization, :set_begin_and_end_dates, :set_product, :set_location

  def lookup
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(product: @product, location: @location).first
      if @inventory_position
        @product_location_assignment = @inventory_position.product_location_assignment
        @min_qty, @on_hand, @available, @on_order, @in_transit, @allocated, @forecasted, @max_qty = [], [],[],[],[],[],[],[]
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => @begin_date, :projected_for.lte => @end_date).all
        @projections.each do |ip|
          @min_qty << @product_location_assignment.minimum_quantity  
          @on_hand << ip.on_hand_quantity
          @available <<  ip.available_quantity
          @on_order <<  ip.on_order_quantity
          @in_transit <<  ip.in_transit_quantity
          @allocated <<  ip.allocated_quantity
          @forecasted <<  ip.forecasted_quantity
          @max_qty <<  @product_location_assignment.maximum_quantity
        end
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
        @product = Product.where(name: params[:inventory_position_search][:product_name]).first
      end
      @product
    end

   def set_location
     if params[:inventory_position_search]
       if !(params[:inventory_position_search][:location_id].blank?)
         @location = Location.find(params[:inventory_position_search][:location_id])
       else
         @location = Location.where(name: params[:inventory_position_search][:location_name]).first
       end
     else
       @location = nil
     end
   end


end
