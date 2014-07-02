class ShipLinesController < ApplicationController
  before_filter :authorize
  before_action :set_ship_line, only: [:show, :edit, :update, :destroy]

  def index
    @user = User.find(session[:user_id])
    @ship_lines = ShipLine.where(organization_id: @user.organization_id).all   
  end

  def lookup
    @user = User.find(session[:user_id])
    @products = Product.all
    @locations = Location.all
    if request.post?
      params[:ship_line].delete_if {|k,v| v.blank?}
      @ship_lines = ShipLine.where(params[:ship_line])
    end
  end


  def show
  end

  def edit
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @products = @user.organization.products
    @order_lines = OrderLine.where(organization_id: @user.organization_id).all
  end

  def update
    @ship_line.eta = full_eta
    @ship_line.assign_attributes(ship_line_params)
    if @ship_line.valid?
      Resque.enqueue(SourceProcessingJob, @ship_line.to_json)
      flash[:notice] = "Ship Line updates have been queued for processing"
      redirect_to lookup_ship_lines_path
    else
      @user = User.find(session[:user_id])
      @location = @ship_line.location.organization.locations
      @products = @ship_line.product.organization.products
      @order_lines = OrderLine.where(organization_id: @user.organization_id).all
      render action: "edit"
    end
  end

  def create
    @ship_line = ShipLine.new(ship_line_params)
    @ship_line.eta = full_eta
    @ship_line.etd = Date.today
    if @ship_line.valid?
      Resque.enqueue(SourceProcessingJob, @ship_line.to_json)
      flash[:notice] = "Ship Lines has been queued for processing"
      redirect_to lookup_ship_lines_path
    else
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      @order_lines = OrderLine.where(organization_id: @user.organization_id).all 
      render action: "new"
    end
  end


  def new
    @ship_line = ShipLine.new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
    @order_lines = OrderLine.where(organization_id: @user.organization_id).all
  end

  def destroy
  end
 
  private

    def ship_line_params
       params.require(:ship_line).permit(:last_shift_date, :parent_movement_source_id, :organization_id, :origin_location_id, :destination_location_id, :product_id, :quantity, :object_reference_number)
    end

    def set_ship_line
      @ship_line = ShipLine.find(params[:id])
    end

    def full_eta
      eta = Date.parse(params[:ship_line][:eta])
    end
   
    def full_etd
      etd = Date.parse(params[:ship_line][:eta])
    end

end
