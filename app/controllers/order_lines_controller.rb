class OrderLinesController < ApplicationController

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
    @order_line = OrderLine.new(params[:order_line])
    if @order_line.save
      Resque.enqueue(SourceProcessingJob, @order_line.id.to_s)
      flash[:notice] = "Order Line has been created succesfully and queued for processing."
      redirect_to order_lines_path
    else
      flash[:notice] = "Error creating Order Line"
      render action: "new"
    end
  end

  def update
  end

  def destroy
  end

  def new
    @user = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
  end


  private
    
    def set_order_line
      @order_line = OrderLine.find(params[:id])
    end  

end


