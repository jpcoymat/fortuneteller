class SourceProcessingJob

  @queue = :new_movement_sources

  attr_accessor :inventory_position

  def self.perform(movement_source_id)
    @movement_source = MovementSource.find(movement_source_id)
    unless @movement_source.nil?
      case @movement_source.class
        when ShipLine
          process_ship_line(@movement_source)
        when OrderLine
          process_order_line(@movement_source)
        when Forecast
          process_forecast(@movement_source)
      end 
    end
  end

  def self.process_ship_line(ship_line)
    origin_inventory_position = origin_position(ship_line)
    unless origin_inventory_position.nil?
      origin_inventory_position.on_hand_quantity -= ship_line.quantity
      origin_inventory_position.
    end
    if track_destination?(ship_line)
    end
  end

  def self.process_order_line(order_line)
  end

  def self.process_forecast(forecast)
  end

  def self.origin_position(movement_source)
    inventory_position = InventoryPosition.where(location_id: movement_source.origin_location_id, product_id: movement_source.product_id).first
  end
  
  def self.destination_position(movement_source)
    inventory_position = InventoryPosition.where(location_id: movement_source.destination_location_id, product_id: movement_source.product_id).first
  end


end
