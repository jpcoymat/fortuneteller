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
    invn_posn.save
    invn_posn.reset_projections
  end

  def self.inventory_position(inventory_adjustment)
    inventory_position = InventoryPosition.where(product_id: inventory_adjustment.product_id, location_id: inventory_adjustment.location_id).first
  end

end

