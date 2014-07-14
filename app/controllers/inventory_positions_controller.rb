class InventoryPositionsController < ApplicationController

  before_filter :authorize
  before_action :set_user, :set_organization, :set_begin_and_end_dates, :set_product, :set_location

  def lookup
    @products = @organization.products
    @locations = @organization.locations
    if request.post?
      @inventory_position = InventoryPosition.where(search_params).where(product: @product).first
      if @inventory_position
        @product_location_assignment = ProductLocationAssignment.where(product: @inventory_position.product, location: @inventory_position.location).first
        @data = []
        @projections = @inventory_position.inventory_projections.where(:projected_for.gte => @begin_date, :projected_for.lte => @end_date).all
        @projections.each do |ip|
          @data << [ip.projected_for,  @product_location_assignment.minimum_quantity,  ip.on_hand_quantity, ip.available_quantity, ip.on_order_quantity, ip.in_transit_quantity, ip.allocated_quantity, ip.forecasted_quantity, @product_location_assignment.maximum_quantity]
        end
      end
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
