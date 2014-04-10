class ShipLinesController < ApplicationController
  before_filter :authorize
  before_action :set_ship_line, only: [:show, :edit, :update, :destroy]

  def index
    @user = User.find(session[:user_id])
    @ship_lines = ShipLine.where(organization_id: @user.organization_id).all   
  end

  def show
  end

  def edit
    @location = @ship_line.location.organization.locations
    @products = @ship_line.product.organization.products
  end

  def update
  end

  def create
    @ship_line = ShipLine.new(ship_line_params)
    @ship_line.eta = full_eta
    @ship_line.etd = Date.today
    if @ship_line.valid?
      Resque.enqueue(SourceProcessingJob, @ship_line.to_json)
      flash[:notice] = "Ship Lines has been queued for processing"
      redirect_to ship_lines_path
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
       params.require(:ship_line).permit(:parent_movement_source_id, :organization_id, :origin_location_id, :destination_location_id, :product_id, :quantity, :object_reference_number)
    end

    def set_ship_line
      @ship_line = ShipLine.find(params[:id])
    end

    def full_eta
      eta = Date.new(params[:ship_line]["eta(1i)"].to_i, params[:ship_line]["eta(2i)"].to_i, params[:ship_line]["eta(3i)"].to_i)
    end

end
