class ForecastsController < ApplicationController
   
  before_action :set_forecast, only:[:show,:edit,:update,:destroy]

  def index
    @user = User.find(session[:user_id])
    @forecasts = @user.organization.forecasts
  end

  def show
  end

  def new
    @forecast = Forecast.new
  end

  def edit
  end

  def update
    if @forecast.update_attributes(forecast_params)
    else
      render action: "edit"  
    end
  end

  def create
    @forecast = Forecast.new(params[:forecast])
    if @forecast.overlaps_with_existing_orders?
      @forecast.quantity = @forecast.original_quantity - @forecast.overlap_quantity
    end
    if @forecast.save
      @inventory_position.add_movement_source(@forecast)
    end
  end

  def destroy
  end

  private
 
    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

end
