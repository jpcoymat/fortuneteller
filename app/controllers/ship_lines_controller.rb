class ShipLinesController < ApplicationController
  before_filter :authorize
  before_action :set_ship_line, only: [:show, :edit, :update, :destroy]

  def index
    @user = User.find(session[:user_id])
    @ship_lines = ShipLine.where(organization_id: @user.organization_id).all   
  end

  def lookup
    @user = User.find(session[:user_id])
    @products = @user.organization.products 
    @locations = @user.organization.locations
    @all_ship_lines = ShipLine.where(organization: @user.organization)
    if request.post?
      @ship_lines = ShipLine.where(search_params)
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
 
  def file_upload
    render partial: "shared/file_upload", locals: {target_path: import_file_ship_lines_path}
  end

  def import_file
    ship_line_file = params[:file]
    copy_ship_line_file(ship_line_file)
    ShipLine.import(Rails.root.join('public','ship_line_uploads').to_s + "/"+ship_line_file.original_filename)
    redirect_to lookup_ship_lines_url
  end


  private

    def ship_line_params
       params.require(:ship_line).permit(:parent_movement_source_object_reference_number, :product_id, :product_name, :last_shift_date, :parent_movement_source_id, :organization_id, :origin_location_id, :destination_location_id, :quantity, :object_reference_number)
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

    def search_params
      search_params = ship_line_params.delete_if {|k,v| v.blank?}
      if search_params.key?("product_name")
        search_params["product_id"] =  Product.where(name: search_params["product_name"]).first.id
        search_params.delete("product_name")
      end
      search_params
    end
  
    def copy_ship_line_file(ship_line_file)
      File.open(Rails.root.join('public','ship_line_uploads',ship_line_file.original_filename),"wb") do |file|
        file.write(ship_line_file.read)
      end
    end


end
