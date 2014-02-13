class ShipmentConfirmation < InventoryAdjustment

  def decrease_location_on_hand
    @inventory_position = InventoryPosition.where(location_id: self.location_id, product_id: self.product_id, organization_id: self.organization_id).first
    @inventory_position.on_hand_qty -= self.shipped_quantity
    @inventory_position.save 
  end

end
