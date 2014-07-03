class OrderLinesController < ApplicationController

  before_filter :authorize
  before_action :set_order_line, only: [:show,:edit,:update,:destroy]

  def lookup
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
    @all_order_lines = OrderLine.where(organization: @user.organization)
    if request.post?
      @order_lines = OrderLine.where(search_params)
    end	
  end


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
      redirect_to lookup_order_lines_path
    else
      flash[:notice] = "Error creating Order Line"
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      render action: "new"
    end
  end

  def update
   @order_line.assign_attributes(order_line_params)
   @order_line.eta = full_eta
   @order_line.etd = full_etd
   if @order_line.valid?
    Resque.enqueue(SourceProcessingJob, @order_line.to_json)
    flash[:notice] = "Order Line updates have been queued for processing."
    redirect_to lookup_order_lines_path
   else
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations	 
    render action: "edit"
   end

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
      params.require(:order_line).permit(:product_name, :last_shift_date, :object_reference_number, :product_id, :origin_location_id, :destination_location_id, :quantity, :organization_id)
    end

    def set_order_line
      @order_line = OrderLine.find(params[:id])
    end  

    def full_eta
      eta = Date.parse(params[:order_line][:eta])
    end

    def full_etd
      etd = Date.parse(params[:order_line][:etd])
    end

    def search_params
      search_params = order_line_params.delete_if {|k,v| v.blank?}
      if search_params.key?("product_name")
        search_params["product_id"] =  Product.where(name: search_params["product_name"]).first.id
        search_params.delete("product_name")
      end
      search_params
    end


end


