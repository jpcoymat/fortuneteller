class ShipLine < MovementSource 

  before_create  :set_etd

  def set_etd
    self.etd = Date.today
  end

 
end
