class Receipt < InventoryAdjustment 

before_create :set_fields


  def set_fields
    self.adjustment_type = "Increase"
    self.adjustment_date = Date.today
  end


end
