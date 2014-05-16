class ProductsController < ApplicationController

  before_filter :authorize  
  before_action :set_product, only: [:show, :edit, :update, :destroy]


  def lookup
    @user = User.find(session[:user_id])
    if request.post?
      params[:product].delete_if {|k,v| v.blank?}
      @products = Product.where(params[:product]).order_by(:name.asc) 
    end
  end

   
  def show
   respond_to do |format|
     format.html
     format.xml {render xml: @product}
     format.json {render json: @product}
   end
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
    respond_to do |format|
      if @product.save
        format.html {redirect_to(lookup_products_path)}
        format.xml {render xml: @product, status: :created, location: @product}
      else
        format.html do 
           @user = User.find(session[:user_id])
           render action: "new"
        end
        format.xml {render xml: @product.errors, status: :unprocessable_entity} 
      end
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

