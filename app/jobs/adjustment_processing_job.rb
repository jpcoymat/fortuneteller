class AdjustmentProcessingJob

  @queue = :inventory_adjustments


  def self.perform(inventory_adjustment_id)
    @inventory_adjustment = InventoryAdjustment.where(id: inventory_adjustment_id).first
    unless @inventory_adjustment.nil?
      case @inventory_adjustment.class
        when InventoryAdvice
          process_inventory_advice(@inventory_adjustment)
        when Receipt
          process_receipt(@inventory_adjustment)
        when ShipmentConfirmation
          process_shipment_confirmation(@inventory_adjustment)  
      end
    end
  end


  def self.process_inventory_advice(inventory_advice)
    invn_posn = inventory_position(inventory_advice)
    invn_posn.on_hand_quantity = inventory_advice.adjustment_quantity
    invn_posn.attribute_breakdown = inventory_advice.attribute_breakdown
    invn_posn.save
    invn_posn.reset_projections
  end

  def self.inventory_position(inventory_adjustment)
    inventory_position = InventoryPosition.where(product_id: inventory_adjustment.product_id, location_id: inventory_adjustment.location_id).first
  end

  def self.process_receipt(receipt)
    invn_posn = inventory_position(receipt)
    if receipt.movement_source
      case receipt.movement_source.class
        when ShipLine
          adjust_ship_line(receipt)
        when OrderLine
          adjust_order_line(receipt)
      end
    end
    invn_posn.on_hand_quantity += receipt.adjustment_quantity
    invn_posn.save
    invn_posn.reset_projections
  end

  def self.adjust_ship_line(receipt)
    ship_line = receipt.movement_source
    adjustment_quantity = 0
    ship_line.quantity - receipt.adjustment_quantity < 0 ? adjustment_quantity = ship_line.quantity : adjustment_quantity = receipt.adjustment_quantity
    ship_line.quantity -= adjustment_quantity
    ship_line.save
    inventory_position = InventoryPosition.where(product: receipt.product, location: receipt.location).first
    if inventory_position
      projection = inventory_position.inventory_projections.where(projected_for: ship_line.eta).first
      if projection
        projection.in_transit_quantity -= adjustment_quantity
        projection.save
        projection.cascade
      end
    end
  end

  def self.adjust_order_line(receipt)
    order_line = receipt.movement_source
    adjustment_quantity = 0
    order_line.quantity - receipt.adjustment_quantity < 0 ? adjustment_quantity = order_line.quantity : adjustment_quantity = receipt.adjustment_quantity
    order_line.quantity -= adjustment_quantity
    order_line.save
    inventory_position = InventoryPosition.where(location: receipt.location, product: receipt.product).first
    if inventory_position
      projection = inventory_position.inventory_projections.where(projected_for: order_line.eta).first
      if projection
        projection.on_order_quantity -= adjustment_quantity
        projection.save
        projection.cascade
      end
    end
  end



end

