class ForecastsController < ApplicationController
  before_filter :authorize   
  before_action :set_forecast, only:[:show,:edit,:update,:destroy]

  def index
    @user = User.find(session[:user_id])
    @forecasts = @user.organization.forecasts
  end

  def lookup
    @user  = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
    if request.post?
      search_params = forecast_params.delete_if {|k,v| v.blank?}
      @forecasts = Forecast.where(search_params) 
    end
  end

  def show
  end

  def new
    @user  = User.find(session[:user_id])
    @products = @user.organization.products
    @locations = @user.organization.locations
    @forecast = Forecast.new
  end

  def edit
  end

  def update
  end

  def create
    @forecast = Forecast.new(forecast_params)  
    @forecast.etd = full_etd
    @forecast.eta = @forecast.etd
    if @forecast.valid?
      Resque.enqueue(SourceProcessingJob, @forecast.to_json)
      flash[:notice] = "Order Line has been created succesfully and queued for processing."
      redirect_to forecasts_path
    else
      flash[:notice] = "Error creating Order Line"
      @user = User.find(session[:user_id])
      @products = @user.organization.products
      @locations = @user.organization.locations
      render action: "new"
    end
  end

  def destroy
  end

  private
 
    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

   def forecast_params
     params.require('forecast').permit(:object_reference_number, :product_id, :origin_location_id, :destination_location_id, :quantity, :organization_id)
   end

   def full_eta
     eta = Date.new(params[:forecast]["eta(1i)"].to_i, params[:forecast]["eta(2i)"].to_i, params[:forecast]["eta(3i)"].to_i)
   end

   def full_etd
     etd = Date.new(params[:forecast]["etd(1i)"].to_i, params[:forecast]["etd(2i)"].to_i, params[:forecast]["etd(3i)"].to_i)
   end
   
end
