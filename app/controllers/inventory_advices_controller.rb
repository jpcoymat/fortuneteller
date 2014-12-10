class InventoryAdvicesController < ApplicationController
  before_filter :authorize   
  before_action :set_inventory_advice, only: [:show, :edit, :update, :destroy]


  def index
    @user = User.find(session[:user_id])
    @inventory_advice = InventoryAdvice.where(organization_id: @user.organization_id).all
  end

  def lookup
    @organization = User.find(session[:user_id]).organization
    @products = @organization.products
    @locations = @organization.locations
    @all_inventory_advices = InventoryAdvice.where(organization: @organization)
    if request.post?
      @inventory_advices = InventoryAdvice.where(search_params)
      @inventory_advices = @inventory_advices.gte(adjustment_date: Date.parse(params[:inventory_advice][:begin_date])) unless params[:inventory_advice][:begin_date].blank?
      @inventory_advices = @inventory_advices.lte(adjustment_date: Date.parse(params[:inventory_advice][:end_date])) unless params[:inventory_advice][:end_date].blank?      
    end
  end

  def show
  end

  def edit
  end

  def update
  end

  def create
    @inventory_advice = InventoryAdvice.new(inventory_advice_params)
    if @inventory_advice.save
      Resque.enqueue(AdjustmentProcessingJob, @inventory_advice.id.to_s)
      redirect_to lookup_inventory_advices_path
    else
      flash[:notice] = "Error creating Inventory Advice"
      @user = User.find(session[:user_id])
      @locations = @user.organization.locations
      @products = @user.organization.products
      render action: "new"
    end
  end

  def destroy
  end

  def new
    @inventory_advice = InventoryAdvice.new
    @user = User.find(session[:user_id])
    @locations = @user.organization.locations
    @products = @user.organization.products
  end

  private
    
    def set_inventory_advice
      @inventory_advice = InventoryAdvice.find(params[:id])
    end  

    def inventory_advice_params
      params.require(:inventory_advice).permit(:product_name, :source, :product_id, :location_id, :organization_id, :object_reference_number, :adjustment_quantity)
    end

    def search_params
      search_params = inventory_advice_params.delete_if {|k,v| v.blank?}
      if search_params.key?("product_name")
        search_params["product_id"] =  Product.where(name: search_params["product_name"]).first.id
        search_params.delete("product_name")
      end
      search_params
    end

    
end
