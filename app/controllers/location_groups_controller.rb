class LocationGroupsController < ApplicationController

  before_filter :authorize
  before_action :set_location_group, only: [:edit, :update]

  def index
    @user = User.find(session[:user_id])
    @location_groups = @user.organization.location_groups
  end

  def edit
   @user = User.find(session[:user_id])
  end

  def update
    if @location_group.update_attributes(location_group_params)
      redirect_to location_groups_path
    else
      @user = User.find(session[:user_id])
      render action: "edit"
    end
  end
 
  def new
    @user = User.find(session[:user_id])
    @location_group = LocationGroup.new
  end

  def create
    @location_group = LocationGroup.new(location_group_params)
    if @location_group.save
      redirect_to location_groups_path
    else
      @user = User.find(session[:user_id])
      render action: "new"
    end
  end


  private

   def set_location_group
     @location_group = LocationGroup.find(params[:id])
   end

  def location_group_params
    params.require(:location_group).permit(:name, :code,  :organization_id)
  end


end
