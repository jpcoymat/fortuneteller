class ReceiptsController < ApplicationController
  before_filter :authorize
  before_action :set_receipt, only: [:show, :edit, :destroy, :update]

  def index
  end

  def show
  end

  def new
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
    
    def set_receipt
      @receipt = Receipt.find(params[:id])
    end
  
end
