class OrderLinesController < ApplicationController
  def index
  end

  def show
  end

  def edit
  end

  def create
    @order_line = OrderLine.new(params[:order_line])
    if @order_line.save
      if @order_line.requires_allocation?
        @inventory_position = InventoryPosition.where(location_id: @order_line.origin_location_id, product_id: @order_line.product_id).first
        @inventory_position.allocate(@order_line)
      end
      if @order_line.requires_on_order?
        @inventory_position = InventoryPosition.where(location_id: @order_line.destination_location_id, product_id: @order_line.product_id).first
        @inventory_position.check_on_order(@order_line)
      end
    end
  end

  def update
  end

  def destroy
  end
end
