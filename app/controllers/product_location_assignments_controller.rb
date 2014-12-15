class ProductLocationAssignmentsController < ApplicationController

  before_filter :authorize
  before_action :set_product_location_assignment, only: [:show, :edit, :update, :destroy]


  def lookup
    @organization = User.find(session[:user_id]).organization
    @locations = @organization.locations
    @products = @organization.products
    if request.post?
      @product_location_assignments = ProductLocationAssignment.where(search_params)
    end
  end

  def index
    @product_location_assignments = User.find(session[:user_id]).product_location_assignments
  end

  def show
  end

  def edit
    @organization = User.find(session[:user_id]).organization
    @locations = @organization.locations
    @products = @organization.products
  end

  def update
    if @product_location_assignment.update_attributes(product_location_assignment_params)
      redirect_to product_location_assignments_path
    else
      @organization = User.find(session[:user_id]).organization
      @location = @organization.locations
      @products = @organization.products
      render action: "edit"
    end
  end

  def new
    @product_location_assignment = ProductLocationAssignment.new
    @organization = User.find(session[:user_id]).organization
    @locations = @organization.locations
    @products = @organization.products
  end

  def create
    @product_location_assignment = ProductLocationAssignment.new(product_location_assignment_params)
    if @product_location_assignment.save
      @product_location_assignment.create_inventory_position
      redirect_to product_location_assignments_path
    else
      @organization = User.find(session[:user_id]).organization
      @locations = @organization.locations
      @products = @organization.products
      render action: "new"
    end
  end

  private

    def set_product_location_assignment
      @product_location_assignment = ProductLocationAssignment.find(params[:id])
    end

    def product_location_assignment_params
      params.require(:product_location_assignment).permit(:location_name, :product_name, :minimum_quantity, :maximum_quantity, :product_id, :location_id)
    end

    def search_params
      searchparams = product_location_assignment_params.delete_if {|k,v| v.blank?}
      if searchparams.key?("product_name")      
        searchparams["product_id"] = Product.where(name: searchparams["product_name"]).first
        searchparams.delete("product_name")     
      end
      if searchparams.key?("location_name")
        searchparams["location_id"] = Location.where(name: searchparams["location_name"]).first
        searchparams.delete("location_name")
      end
      searchparams
    end

end

