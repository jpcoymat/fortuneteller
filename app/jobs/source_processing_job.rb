class SourceProcessingJob

  @queue = :new_movement_sources

  def self.perform(movement_source_id)
    Resque.logger.info("Here we go ...")
    @movement_source = MovementSource.find(movement_source_id)
    unless @movement_source.nil?
      Resque.logger.info("Found Movement Source")
      case @movement_source.class
        when ShipLine
          Resque.logger.info("I am a ship line")
          process_ship_line(@movement_source)
        when OrderLine
          process_order_line(@movement_source)
        when Forecast
          process_forecast(@movement_source)
      end 
    end
  end

  def self.process_ship_line(ship_line)
    Resque.logger.info("process ship line starting ..")
    origin_inventory_position = origin_position(ship_line)
    unless origin_inventory_position.nil?
      Resque.logger.info("Found origin position: Product: " + origin_inventory_position.product.name + " - Location: " + origin_inventory_position.location.name + " - On Hand Qty: " + origin_inventory_position.on_hand_quantity.to_s) 
      origin_inventory_position.on_hand_quantity -= ship_line.quantity
      Resque.logger.info("New On Hand Quantity: " + origin_inventory_position.on_hand_quantity.to_s)
      origin_inventory_position.save
      origin_inventory_position.reset_projections
    end
    destination_inventory_position = destination_position(ship_line) 
    unless destination_inventory_position.nil?
     Resque.logger.info("Found destination position: Product: " + destination_inventory_position.product.name + " - Location: " + destination_inventory_position.location.name)
     po_line = ship_line.parent_movement_source
     unless po_line.nil?
       position = destination_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
       unless position.nil?
         position.on_order_quantity -= ship_line.quantity
       end
     end
     projection = destination_inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
     unless projection.nil?
       Resque.logger.info("Found projection - Date: " + projection.projected_for.to_s + " - In Transit quantity: " + projection.in_transit_quantity.to_s)
       projection.in_transit_quantity += ship_line.quantity
       Resque.logger.info("New In Transit Qty: " + projection.in_transit_quantity.to_s)
       projection.save   
     end 
     destination_inventory_position.save
     destination_inventory_position.reset_projections
    end
  end

  def self.process_order_line(order_line)
   Resque.logger.info("process order line starting ..")
   origin_inventory_position = origin_position(order_line)
   unless origin_inventory_position.nil? 
     Resque.logger.info("Found origin position: Product: " + origin_inventory_position.product.name + " - Location: " + origin_inventory_position.location.name + " - On Hand Qty: " + origin_inventory_position.on_hand_quantity.to_s)
     origin_projection = origin_inventory_position.inventory_projections.where(projected_for: order_line.etd).first
     if origin_projection
       origin_projection.allocated_quantity += order_line.quantity
       origin_projection.save
       origin_projection.cascade
     end
   end
   destination_inventory_position = destination_position(order_line)
   if destination_inventory_position
     destination_projection = destination_inventory_position.inventory_projections.where(projected_for: order_line.eta).first
     if destination_projection
       destination_projection.on_order_quantity += order_line.quantity
       destination_projection.save
       destination_projection.cascade
     end
   end
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
