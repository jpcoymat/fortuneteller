class ForecastsController < ApplicationController
   
  before_action :set_forecast, only:[:show,:edit,:update,:destroy]

  def index
  end

  def show
  end

  def new
  end

  def edit
  end

  def update
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
