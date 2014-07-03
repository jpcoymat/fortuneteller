class ShipLine < MovementSource 

  before_create  :set_etd

  def parent_movement_source_object_reference_number
    self.parent_movement_source.try(:object_reference_number)
  end

  def parent_movement_source_object_reference_number=(ref_number)
    self.parent_movement_source = OrderLine.where(object_reference_number: ref_number).first
  end

  def set_etd
    self.etd = Date.today
  end

  def create_shipment_confirmation
    @shipment_confirmation = ShipmentConfirmation.new(organization: self.organization, source: self.source, product: self.product, location: self.origin_location, adjustment_quantity: self.quantity, adjustment_date: self.etd, movement_source: self)
    @shipment_confirmation   
  end

  def parent_movement_source_object_reference_number
    
  end

 
end
