class ForecastsController < ApplicationController
  before_filter :authorize   
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
  end

  def create
  end

  def destroy
  end

  private
 
    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

end
