class ProductsController < ApplicationController

  before_filter :authenticate_user  

  def lookup
    @user = User.find(session[:user_id])
    if request.post?
      params[:product].delete_if {|k,v| v.blank?}
      @products = Product.where(params[:product]).all 
    end
  end

   
  def show
    @product = Product.find(params[:id])
  end
  
  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.save
      redirect_to product_path(@product)
    else
      render action: "edit"
    end
  end

  def new
    @product = Product.new
    @user = User.find(session[:user_id])
  end

  def create
    @product = Product.new(params[:product])
    if @product.save
      redirect_to product_path(@product)
    else
     @user = User.find(session[:user_id])
     render action: "new"
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.is_active = false
    @product.save
    redirect_to lookup_products_path
  end

end

