class ShipmentConfirmation < InventoryAdjustment

  before_create :set_fields
  

  def set_fields
    self.adjustment_type = "Decrease"
    self.source = "Fortuneteller"
    set_object_reference_number
  end 
 
  def set_object_reference_number
    if self.object_reference_number.nil?
      object_reference = generate_reference_number
      while reference_number_exists?(object_reference)
        object_reference = generate_reference_number
      end
      self.object_reference_number = object_reference
    end
  end
  
  def generate_reference_number
    "SC" + self.product.code + self.location.code + self.adjustment_date.to_s + (rand()*1000).floor.to_s.rjust(4,"0")
  end

  def reference_number_exists?(object_ref_num)
    ShipmentConfirmation.where(object_reference_number: object_ref_num).all.count > 0
  end


end
