class ShipLine < MovementSource


  def requires_origin_decrement?
    product_location_assignment = ProductLocationAssignment.where(product_id: self.product_id, location_id: self.origin_location_id).first
    !(product_location_assignment.nil?) #return true if PLA is non-nil, false otherwise
  end  

  def origin_inventory_position
    inventory_position = InventoryPosition.where(product_id: self.product_id, location_id: self.origin_location_id).first
  end

  def save
    if super
      if trackable?
        if requires_origin_decrement?
        else
           
        end
      end 
    end
  end
 end
