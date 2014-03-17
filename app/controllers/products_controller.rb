class ProductsController < ApplicationController

  before_filter :authorize  
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def lookup
    @user = User.find(session[:user_id])
    if request.post?
      params[:product].delete_if {|k,v| v.blank?}
      @products = Product.where(params[:product]).all 
    end
  end

   
  def show
  end
  
  def edit
  end

  def update
    if @product.update_attributes(product_params)
      redirect_to lookup_products_path 
    else
      render action: "edit"
    end
  end

  def new
    @product = Product.new
    @user = User.find(session[:user_id])
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to lookup_products_path
    else
     @user = User.find(session[:user_id])
     render action: "new"
    end
  end

  def destroy
    @product.is_active = false
    @product.save
    redirect_to lookup_products_path
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :code, :product_category, :organization_id)
    end

end

