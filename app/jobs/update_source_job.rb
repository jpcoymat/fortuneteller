class UpdateSourceJob

  @queue = :new_movement_sources

  def self.perform(movement_source_id, field_change, old_value, new_value)
    @movement_source = MovementSource.where(id: movement_source_id).first
    if @movement_source
      case @movement_source.class
        when ShipLine
          update_ship_line(@movement_source, field_change, old_value, new_value) 
        when OrderLine
          update_order_line(@movement_source, field_change, old_value, new_value)
        when Forecast
          update_forecast(@movement_source, field_change, old_value, new_value) 
      end
    end
  end


  def self.update_ship_line(movement_source, field_change, old_value, new_value)
    case field_change
      when "eta"
        update_ship_line_eta(movement_source, old_value, new_value) 
      when "etd"
        update_ship_line_etd(movement_source, old_value, new_value)
      when "destination_location_id"
        
      when "quantity"
        update_ship_line_quantity(movement_source, old_value, new_value) 
    end
  end


  def self.update_ship_line_quantity(movement_source, old_value, new_value)
    origin_position = InventoryPosition.where(location: movement_source.origin_location, product: movement_source.product).first
    if origin_position
      update_origin_position(origin_position, old_value, new_value)
    end
    destination_position = InventoryPosition.where(location: movement_source.destination_location, product: movement_source.product).first
    if destination_position
      projection = destination_position.inventory_projections.where(projected_for: movement_source.eta)
      if projection
        update_destination_in_transit_projection(projection, old_value, new_value)
      end
    end
  end

  def self.update_destination_in_transit_projection(inventory_projection, old_value, new_value)
    change_quantity = new_value - old_value
    inventory_projection.in_transit_quantity += change_quantity
    inventory_projection.save
    inventory_projection.cascade
  end

  def self.update_origin_position(inventory_position, old_value, new_value)
    change_quantity = new_value - old_value
    inventory_position.on_hand_quantity += change_quantity
    inventroy_position.save
    inventory_position.reset_projections
  end




end
