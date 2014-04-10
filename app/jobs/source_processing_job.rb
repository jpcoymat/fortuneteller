class SourceProcessingJob

  @queue = :new_movement_sources

  def self.perform(json_string)
    Resque.logger.info("Here we go ...")
    object_hash = JSON.load(json_string)
    if object_hash.has_key?("order_line")
      order_line = OrderLine.new(object_hash["order_line"])
      process_order_line(order_line)
    elsif object_hash.has_key?("ship_line")
      ship_line = ShipLine.new(object_hash["ship_line"])
      process_ship_line(ship_line)
    elsif object_hash.has_key?("forecast")
      forecast = Forecast.new(object_hash["forecast"])
      process_forecast(forecast)
    end
  end

  def self.process_ship_line(ship_line)
    id_count = ShipLine.where(id: ship_line.id).all.count
    id_count == 0 ? process_new_ship_line(ship_line) : process_updated_ship_line(ship_line)
  end
  

  def self.process_new_ship_line(ship_line)
    ship_line.save
    po_line = OrderLine.where(id: ship_line.parent_movement_source_id).first
    origin_inventory_position = origin_position(ship_line)
    destination_inventory_position = destination_position(ship_line)
    amount_to_decrement = 0
    if po_line
      po_line.quantity - ship_line.quantity < 0 ? amount_to_decrement = po_line.quantity : amount_to_decrement = ship_line.quantity
      po_line.quantity -= amount_to_decrement
      po_line.save
    end
    if origin_inventory_position
      if po_line
	projection = origin_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
        if projection
	  projection.allocated_quantity -= amount_to_decrement
	  projection.save
        end
      end
      ship_line.create_shipment_confirmation
      origin_inventory_position.on_hand_quantity -= ship_line.quantity
      origin_inventory_position.save
      origin_inventory_position.reset_projections
    end
    if destination_inventory_position
      if po_line
        order_projection = destination_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
        if projection
          order_projection.on_order_quantity -= amount_to_decrement
          order_projection.save
        end
      end
      projection = destination_inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
      if projection
        projection.in_transit_quantity += ship_line.quantity
        projection.save
      end
      destination_inventory_position.save
      destination_inventory_position.reset_projections
    end
  end

  def self.process_order_line(order_line)
    id_count = OrderLine.where(id: order_line.id).all.count
    id_count == 0 ? process_new_order_line(order_line) : process_updated_order_line(order_line)
  end

  def self.process_new_order_line(order_line)
   order_line.save
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

  def self.process_updated_order_line(order_line)
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
