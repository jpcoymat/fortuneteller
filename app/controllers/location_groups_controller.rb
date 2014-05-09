class LocationGroupsController < ApplicationController

  before_filter :authorize
  before_action :set_location_group, only: [:show, :edit, :update, :destroy]

  private

   def set_location
     @location_group = LocationGroup.find(params[:id])
   end


end
