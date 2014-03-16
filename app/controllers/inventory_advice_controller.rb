class InventoryAdviceController < ApplicationController
   
  before_action :set_inventory_advice, only: [:show, :edit, :update, :destroy]


  def index
  end

  def show
  end

  def edit
  end

  def update
  end

  def create
  end

  def destroy
  end

  def new
  end

  private
    
    def set_inventory_advice
      @inventory_advice = InventoryAdvice.find(params[:id])
    end  
    
end
