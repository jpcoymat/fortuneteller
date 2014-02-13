class InventoryAdvice < InventoryAdjustment

  def initialize
    self.adjustment_action = "Overwrite"
#    self.legacy_persistance = false
  end

end
