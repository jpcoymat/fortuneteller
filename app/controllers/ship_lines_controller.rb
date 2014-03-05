class ShipLinesController < ApplicationController
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
end
