class ProductLocationAssignment
  include Mongoid::Document
  include Mongoid::Timestamps  
  field :minimum_quantity, type: Integer
  field :maximum_quantity, type: Integer 
  field :is_active, type: Boolean

  belongs_to :product
  belongs_to :location

  validates :product_id, uniqueness: {scope: :location_id}

  def create_inventory_position
    @inventory_position = InventoryPosition.new
    @inventory_position.product = self.product
    @inventory_position.location = self.location
    @inventory_position.on_hand_quantity, @inventory_position.forecasted_quantity, @inventory_position.on_order_quantity, @inventory_position.in_transit_quantity, @inventory_position.allocated_quantity = 0,0,0,0,0
    @inventory_position.save
    @inventory_position.create_projections
  end

end
