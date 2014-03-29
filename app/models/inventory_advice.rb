class InventoryAdvice < InventoryAdjustment


  before_create :set_fields


  def set_fields
    self.adjustment_type = "Overwrite"
    self.adjustment_date = Date.today
  end



end
