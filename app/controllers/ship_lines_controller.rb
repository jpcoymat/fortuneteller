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
    if @ship_line.save
      Resque.enqueue(SourceProcessingJob, @ship_line.id.to_s)
    end
  end


  def new
    @ship_line = ShipLine.new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @location = @user.organization.locations
  end

  def destroy
  end
 
  private

    def ship_line_params
       params.require(:ship_line).permit(:origin_location_id, :destination_location_id, :product_id:, :original_quantity, :eta, :etd)
    end

    def set_ship_line
      @ship_line = ShipLine.find(params[:id])
    end

end
