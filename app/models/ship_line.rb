class ShipLine < MovementSource 

  before_create  :set_etd



  def set_etd
    self.etd = Date.today
  end

  def create_shipment_confirmation
    @shipment_confirmation = ShipmentConfirmation.new(organization: self.organization, source: self.source, product: self.product, location: self.origin_location, adjustment_quantity: self.quantity, adjustment_date: self.etd, movement_source: self)
    @shipment_confirmation   
  end

 
end
