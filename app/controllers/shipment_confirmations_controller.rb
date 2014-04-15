class ShipmentConfirmationsController < ApplicationController

  before_filter :authorize
  before_action :set_shipment_confirmation, only: [:show]

  
  def index
    @user = User.find(session[:user_id])
    @organization = @user.organization
    @shipment_confirmations = ShipmentConfirmation.where(organization_id: @organization.id).all
  end

  def show
  end

  protected
   
    def set_shipment_confirmation
      @shipment_confirmation = ShipmentConfirmation.find(params[:id])
    end

 

end

