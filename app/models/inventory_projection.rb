class InventoryProjection
  include Mongoid::Document
  include Mongoid::Timestamps
  field :on_hand_quantity, type: Float
  field :forecasted_quantity, type: Float
  field :allocated_quantity, type: Float
  field :on_order_quantity, type: Float
  field :in_transit_quantity, type: Float
  field :projected_for, type: Date

  embedded_in :inventory_position

  validates :on_hand_quantity, :forecasted_quantity, :allocated_quantity, :in_transit_quantity, :on_order_quantity, :projected_for, presence: true

  def available_quantity 
    @available_quantity = self.on_hand_quantity + self.in_transit_quantity + self.on_order_quantity - self.allocated_quantity 
    @available_quantity
  end

  def yesterday
    @yesterday = self.inventory_position.inventory_projections.where(projected_for: (self.projected_for - 1.day)).first
  end

  def tomorrow 
    @tomorrow = self.inventory_position.inventory_projections.where(projected_for: (self.projected_for + 1.day)).first
  end

  def calculate_on_hand_quantity
    yesterday.nil? ? self.on_hand_quantity = self.inventory_position.on_hand_quantity : self.on_hand_quantity = yesterday.available_quantity
  end

  def set_all_fields
    set_on_order_quantity
    set_in_transit_quantity
    set_allocated_quantity
    set_forecasted_quantity
  end


  def set_on_order_quantity
    self.on_order_quantity = OrderLine.where(product_id: self.inventory_position.product_id, destination_location_id: self.inventory_position.location_id, eta: self.projected_for).sum(:quantity)
  end

  def set_in_transit_quantity
    self.in_transit_quantity = ShipLine.where(product_id: self.inventory_position.product_id, destination_location_id: self.inventory_position.location_id, eta: self.projected_for).sum(:quantity)
  end
  
  def set_allocated_quantity
    self.allocated_quantity = OrderLine.where(product_id: self.inventory_position.product_id, origin_location_id: self.inventory_position.location_id, etd: self.projected_for).sum(:quantity)
  end

  def set_forecasted_quantity
    self.forecasted_quantity = Forecast.where(product_id: self.inventory_position.product_id, origin_location_id: self.inventory_position.location_id, etd: self.projected_for).sum(:quantity)
  end

  def cascade
    self.inventory_position.inventory_projections.where(:projected_for.gt => self.projected_for).each  {|projection| projection.calculate_on_hand_quantity}
    self.inventory_position.save
  end



end
