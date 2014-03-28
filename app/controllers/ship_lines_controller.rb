class ShipLinesController < ApplicationController

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
    @ship_line.eta, @ship_line.etd = full_eta, full_etd
    if @ship_line.save
      Resque.enqueue(SourceProcessingJob, @ship_line.id.to_s)
      flash[:notice] = "Ship Lines has been created succesfully queued for processing"
      redirect_to ship_lines_path
    else 
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      render action: "new"
    end
  end


  def new
    @ship_line = ShipLine.new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
  end

  def destroy
  end
 
  private

    def ship_line_params
       params.require(:ship_line).permit(:organization_id, :origin_location_id, :destination_location_id, :product_id, :quantity, :object_reference_number)
    end

    def set_ship_line
      @ship_line = ShipLine.find(params[:id])
    end

    def full_eta
      eta = Date.new(params[:ship_line]["eta(1i)"].to_i, params[:ship_line]["eta(2i)"].to_i, params[:ship_line]["eta(3i)"].to_i)
    end

    def full_etd
      etd = Date.new(params[:ship_line]["etd(1i)"].to_i, params[:ship_line]["etd(2i)"].to_i, params[:ship_line]["etd(3i)"].to_i)
    end

end
