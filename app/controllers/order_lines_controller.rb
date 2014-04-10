class OrderLinesController < ApplicationController
  before_filter :authorize
  before_action :set_order_line, only: [:show,:edit,:update,:destroy]

  def index
    @user = User.find(session[:user_id])
    @order_lines = OrderLine.where(organization_id: @user.organization_id).all
  end

  def show
  end

  def edit
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
  end

  def create
    @order_line = OrderLine.new(order_line_params)
    @order_line.eta = full_eta
    @order_line.etd = full_etd
    if @order_line.valid?
      Resque.enqueue(SourceProcessingJob, @order_line.to_json)
      flash[:notice] = "Order Line has been created succesfully and queued for processing."
      redirect_to order_lines_path
    else
      flash[:notice] = "Error creating Order Line"
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      render action: "new"
    end
  end

  def update
  end

  def destroy
  end

  def new
    @order_line = OrderLine.new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
  end


  private
    
    def order_line_params
      params.require(:order_line).permit(:object_reference_number, :product_id, :origin_location_id, :destination_location_id, :quantity, :organization_id)
    end

    def set_order_line
      @order_line = OrderLine.find(params[:id])
    end  

    def full_eta
      eta = Date.new(params[:order_line]["eta(1i)"].to_i, params[:order_line]["eta(2i)"].to_i, params[:order_line]["eta(3i)"].to_i)
    end

    def full_etd
      etd = Date.new(params[:order_line]["etd(1i)"].to_i, params[:order_line]["etd(2i)"].to_i, params[:order_line]["etd(3i)"].to_i)
    end
end


