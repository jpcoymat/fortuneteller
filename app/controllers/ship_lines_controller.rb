class ShipLinesController < ApplicationController

  before_action :set_ship_line, only: [:show, :edit, :update, :destroy]

  def index
  
  end

  def show
  end

  def edit
  end

  def update
  end

  def create
    @ship_line = ShipLine.new(params[:ship_line])
    if @ship_line.trackable?
      if @ship_line.requires_origin_decrement
      end
    end 
  end

  def destroy
  end
 
  private

    def set_ship_line
      @ship_line = ShipLine.find(params[:id])
    end

end
