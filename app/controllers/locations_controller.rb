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
    if @location.update_attributes(params[:location])
      redirect_to location_path(@location)
    else
      render action: "edit"
    end
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(params[:location])
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


end

