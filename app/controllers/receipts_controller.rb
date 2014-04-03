class ReceiptsController < ApplicationController
  before_filter :authorize
  before_action :set_receipt, only: [:show, :edit, :destroy, :update]

  def index
    @user = User.find(session[:user_id])
    @receipts = Receipt.where(organization_id: @user.organization_id).all
  end

  def show
  end

  def new
    @receipt = Receipt.new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations 
    @movement_sources = @user.organization.movement_sources
  end

  def edit
  end

  def update
  end

  def create
    @receipt = Receipt.new(receipt_params)
    if @receipt.save
      Resque.enqueue(AdjustmentProcessingJob,@receipt.id.to_s)
      flash[:notice] = "Receipt has been created succesfully and has been queued for processing"
      redirect_to receipts_path
    else
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      @movement_sources = @user.organization.movement_sources
      render action: "new"
    end
  end

  def destroy
  end

  private
    
    def set_receipt
      @receipt = Receipt.find(params[:id])
    end

    def receipt_params
      params.require('receipt').permit(:source, :object_reference_number, :adjustment_quantity, :product_id, :location_id, :organization_id, :movement_source_id)
    end
  
end
