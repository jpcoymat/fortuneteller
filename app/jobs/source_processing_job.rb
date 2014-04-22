class SourceProcessingJob

  @queue = :new_movement_sources

  def self.perform(json_string)
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
    if ship_line.save
      project_ship_line(ship_line)
    end
  end


  def self.project_ship_line(ship_line)
     Resque.logger.info("Starting Ship line projection")
    po_line = OrderLine.where(id: ship_line.parent_movement_source_id).first
    origin_inventory_position = origin_position(ship_line)
    destination_inventory_position = destination_position(ship_line)
    amount_to_decrement = 0
    if po_line
       Resque.logger.info("Found associated PO Line with Ship Line")
      amount_to_decrement = [ship_line.quantity, po_line.quantity].min
      po_line.quantity -= amount_to_decrement
      po_line.save
    end
    if origin_inventory_position
      if po_line
        projection = origin_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
        if projection
          Resque.logger.info("Found projection associated with order line: " + projection.projected_for.to_s)
          projection.allocated_quantity -= amount_to_decrement
          projection.save
        end
      end
      shipment_confirmation = ship_line.create_shipment_confirmation
      shipment_confirmation.set_fields
      Resque.logger.info("Shipment confirmation created " + shipment_confirmation.object_reference_number)
      if shipment_confirmation.save
        Resque.logger.info("Ship confirm saved")
        origin_inventory_position.on_hand_quantity -= ship_line.quantity
        origin_inventory_position.save
        origin_inventory_position.reset_projections
      end
    end
    if destination_inventory_position
      if po_line
        order_projection = destination_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
        if order_projection
          Resque.logger.info("Projection associated with parent object for date :" + order_projection.projected_for.to_s) 
          order_projection.on_order_quantity -= amount_to_decrement
          order_projection.save
        end
      end
      projection = destination_inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
      if projection
        Resque.logger.info("Projection for Shipline for " + projection.projected_for.to_s + ".  Current InTran qty: " + projection.in_transit_quantity.to_s)
        projection.in_transit_quantity += ship_line.quantity
        Resque.logger.info("Update in transit qty " + projection.in_transit_quantity.to_s)
        projection.save
        projection.cascade
      end
    end
  end


  def self.process_order_line(order_line)
    id_count = OrderLine.where(id: order_line.id).all.count
    id_count == 0 ? process_new_order_line(order_line) : process_updated_order_line(order_line)
  end

  def self.process_new_order_line(order_line)
    if order_line.save
       project_order_line(order_line)
    end
  end
  

  def self.project_order_line(order_line)
   origin_inventory_position = origin_position(order_line)
   unless origin_inventory_position.nil? 
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
    original_order_line = OrderLine.where(id: order_line.id).first
    undo_order_line(original_order_line)
    project_order_line(order_line) 
    original_order_line.update_attributes(order_line.attributes)
  end

  def self.undo_order_line(order_line)
    origin_inventory_position = origin_position(order_line)
    unless origin_inventory_position.nil?
      origin_projection = origin_inventory_position.inventory_projections.where(projected_for: order_line.etd).first
      if origin_projection
        origin_projection.allocated_quantity -= order_line.quantity
        origin_projection.save
        origin_projection.cascade
      end
    end
    destination_inventory_position = destination_position(order_line)
    if destination_inventory_position
      destination_projection = destination_inventory_position.inventory_projections.where(projected_for: order_line.eta).first
      if destination_projection
        destination_projection.on_order_quantity -= order_line.quantity
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

  def self.process_updated_ship_line(ship_line)
    original_ship_line = ShipLine.find(ship_line.id)
    Resque.logger.info("Original Ship Line: " + original_ship_line.to_json)
    Resque.logger.info("Updated Ship Line: " + ship_line.to_json)
    undo_ship_line(original_ship_line)
    Resque.logger.info("Done with undo, no redoing new line")
    project_ship_line(ship_line)
    original_ship_line.update_attributes(ship_line.attributes)
  end
  

  def self.undo_ship_line(ship_line)
    return_to_parent(ship_line)
    origin_inventory =  origin_position(ship_line)
    if origin_inventory
      Resque.logger.info("Origin invn: " + origin_inventory.product.name + " - " + origin_inventory.location.name + " / On Hand Qty: " + origin_inventory.on_hand_quantity.to_s)  
      origin_inventory.on_hand_quantity += ship_line.quantity
      Resque.logger.info("New On Hand Quantity: " + origin_inventory.on_hand_quantity.to_s)
      origin_inventory.save
      origin_inventory.reset_projections      
    end
    destination_inventory = destination_position(ship_line)
    if destination_inventory
      Resque.logger.info("Destn Invn: " + destination_inventory.product.name + " - " + destination_inventory.location.name + " / On Hand Qty: ")
      destination_projection = destination_inventory.inventory_projections.where(projected_for: ship_line.eta).first
      if destination_projection
        Resque.logger.info("Found projection for date " + destination_projection.projected_for.to_s)
        destination_projection.in_transit_quantity -= ship_line.quantity
        destination_projection.save
        destination_projection.cascade
      end
    end
  end

  def self.return_to_parent(ship_line)
    order_line = ship_line.parent_movement_source
    if order_line
      Resque.logger.info("Updating Order Line " + order_line.object_reference_number + " - Current Qty: " + order_line.quantity.to_s)
      order_line.quantity += ship_line.quantity
      order_line.save
      Resque.logger.info("New Qty: " + order_line.quantity.to_s)
      origin_inventory = origin_position(order_line)
      if origin_inventory
        Resque.logger.info("Updating On Hand Inv at Origin for loc " + origin_inventory.location.name + " and prod " + origin_inventory.product.name)
        origin_projection = origin_inventory.inventory_projections.where(projected_for: order_line.etd).first
        origin_projection.allocated_quantity += ship_line.quantity
        origin_projection.save
        origin_projection.cascade
      end
      destination_inventory = destination_position(ship_line)
      if destination_inventory
        Resque.logger.info("Updating OO qty at dest for loc " + destination_inventory.location.name + " and prod " + destination_inventory.product.name)
        destination_projection = destination_inventory.inventory_projections.where(projected_for: order_line.eta).first
        if destination_projection
          Resque.logger.info("Updating projection record for date " + destination_projection.projected_for.to_s) 
          destination_projection.on_order_quantity += ship_line.quantity
          destination_projection.save
          destination_projection.cascade 
        end
      end
    end
  end

end

