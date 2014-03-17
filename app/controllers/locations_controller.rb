class LocationsController < ApplicationController

  before_filter :authorize
  before_action :set_location, only: [:show, :edit, :update, :destroy]

  def index
    @locations = User.find(session[:user_id]).organization.locations
  end
  
  def show
  end
 
  def edit
  end

  def update
    if @location.update_attributes(location_params)
      redirect_to location_path(@location)
    else
      render action: "edit"
    end
  end

  def new
    @user = User.find(session[:user_id])
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)
    if @location.save
      redirect_to location_path(@location)
    else
      render action: "new"
    end
  end

  def destroy
    @location.is_active = false
    @location.save
    redirect_to locations_path
  end

  private
  
    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.require(:location).permit(:name, :code, :address_1, :address_2, :city, :state_providence, :country, :postal_code, :organization_id)
    end

end

