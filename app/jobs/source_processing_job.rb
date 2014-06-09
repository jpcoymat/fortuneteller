class SourceProcessingJob

  @queue = :new_movement_sources

  def self.perform(json_string)
    Resque.logger.info("loading string hash")
    object_hash = JSON.load(json_string)
    if object_hash.has_key?("order_line")
      Resque.logger.info("its an order line")
      order_line = OrderLine.new(object_hash["order_line"])
      process_order_line(order_line)
    elsif object_hash.has_key?("ship_line")
      Resque.logger.info("its a ship line")
      ship_line = ShipLine.new(object_hash["ship_line"])
      process_ship_line(ship_line)
    elsif object_hash.has_key?("forecast")
      Resque.logger.info("its a forecast")
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
    po_line = OrderLine.where(id: ship_line.parent_movement_source_id).first
    origin_inventory_position = origin_position(ship_line)
    destination_inventory_position = destination_position(ship_line)
    amount_to_decrement = 0
    if po_line
      amount_to_decrement = [ship_line.quantity, po_line.quantity].min
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
      shipment_confirmation = ship_line.create_shipment_confirmation
      shipment_confirmation.set_fields
      if shipment_confirmation.save
        origin_inventory_position.on_hand_quantity -= ship_line.quantity
        origin_inventory_position.save
        origin_inventory_position.reset_projections
      end
    end
    if destination_inventory_position
      if po_line
        order_projection = destination_inventory_position.inventory_projections.where(projected_for: po_line.eta).first
        if order_projection 
          order_projection.on_order_quantity -= amount_to_decrement
          order_projection.save
        end
      end
      projection = destination_inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
      if projection
        projection.in_transit_quantity += ship_line.quantity
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
   if origin_inventory_position
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
    if origin_inventory_position
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
    Resque.logger.info("Checking if forecast exists")
    id_count = Forecast.where(id: forecast.id).all.count
    Resque.logger.info("Total record count: " + id_count.to_s)
    id_count == 0 ? process_new_forecast(forecast) : process_updated_forecast(forecast) 
  end

  def self.origin_position(movement_source)
    inventory_position = InventoryPosition.where(location_id: movement_source.origin_location_id, product_id: movement_source.product_id).first
  end
  
  def self.destination_position(movement_source)
    inventory_position = InventoryPosition.where(location_id: movement_source.destination_location_id, product_id: movement_source.product_id).first
  end

  def self.process_updated_ship_line(ship_line)
    original_ship_line = ShipLine.find(ship_line.id)
    undo_ship_line(original_ship_line)
    project_ship_line(ship_line)
    original_ship_line.update_attributes(ship_line.attributes)
  end
  

  def self.undo_ship_line(ship_line)
    return_to_parent(ship_line)
    origin_inventory =  origin_position(ship_line)
    if origin_inventory  
      origin_inventory.on_hand_quantity += ship_line.quantity
      origin_inventory.save
      origin_inventory.reset_projections      
    end
    destination_inventory = destination_position(ship_line)
    if destination_inventory
      destination_projection = destination_inventory.inventory_projections.where(projected_for: ship_line.eta).first
      if destination_projection
        destination_projection.in_transit_quantity -= ship_line.quantity
        destination_projection.save
        destination_projection.cascade
      end
    end
  end

  def self.return_to_parent(ship_line)
    order_line = ship_line.parent_movement_source
    if order_line
      order_line.quantity += ship_line.quantity
      order_line.save
      origin_inventory = origin_position(order_line)
      if origin_inventory
        origin_projection = origin_inventory.inventory_projections.where(projected_for: order_line.etd).first
        origin_projection.allocated_quantity += ship_line.quantity
        origin_projection.save
        origin_projection.cascade
      end
      destination_inventory = destination_position(ship_line)
      if destination_inventory
        destination_projection = destination_inventory.inventory_projections.where(projected_for: order_line.eta).first
        if destination_projection
          destination_projection.on_order_quantity += ship_line.quantity
          destination_projection.save
          destination_projection.cascade 
        end
      end
    end
  end

  def self.process_new_forecast(forecast)
    if forecast.save 
      project_forecast(forecast)
    end
  end

  def self.project_forecast(forecast)
    origin_inventory_position = origin_position(forecast)
    if origin_inventory_position
      origin_projection = origin_inventory_position.inventory_projections.where(projected_for: forecast.etd).first
      if origin_projection
        origin_projection.forecasted_quantity += forecast.quantity
        origin_projection.save
        origin_projection.cascade
      end
    end
  end

  def self.process_updated_forecast(forecast)
    original_forecast = Forecast.find(forecast.id)
    undo_forecast(original_forecast)
    if original_forecast.update_attributes(forecast.attributes)
      project_forecast(forecast)
    end
  end

  def self.undo_forecast(forecast)
    inventory_position = origin_position(forecast)
    if inventory_position
      projection = inventory_position.inventory_projections.where(projected_for: forecast.etd).first
      if projection
        projection.forecasted_quantity -= forecast.quantity
        projection.save
        projection.cascade
      end
    end
  end
  

end

