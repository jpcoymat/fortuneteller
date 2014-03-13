class LocationsController < ApplicationController


  def index
    @locations = User.find(session[:user_id).organization.locations
  end
  
  def show
    @location = Location.find(params[:id])
  end
 
  def edit
    @location = Location.find(params[:id])
  end

  def update
    @location = Location.find(params[:id])
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
    @location = Location.find(params[:id])
    @location.is_active = false
    @location.save
    redirect_to locations_path
  end


end

