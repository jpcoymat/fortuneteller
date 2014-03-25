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
      origin_inventory_position.reset_projections
    end
    destination_inventory_position = destination_position(ship_line) 
    unless destination_inventory_position.nil?
     po_line = ship_line.parent_movement_source
     unless po_line.nil?
       position = destination_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
       unless position.nil?
         position.on_order_quantity -= ship_line.quantity
       end
     end
     position = destination_inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
     unless position.nil?
       position.in_transit_quantity += ship_line.quantity
     end 
     destination_inventory_position.save
     destination_inventory_position.reset_projections
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
