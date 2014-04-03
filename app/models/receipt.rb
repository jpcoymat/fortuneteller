class Receipt < InventoryAdjustment 

before_create :set_fields

validate :movement_source_match


  def set_fields
    self.adjustment_type = "Increase"
    self.adjustment_date = Date.today
  end


  protected
   

    def movement_source_match
      unless self.movement_source_id.nil?
        if self.movement_source.destination_location != self.location or self.movement_source.product != self.product
          errors.add(:base, "Product and/or Location Does not match those on movement source.")
        end
      end
    end


end
