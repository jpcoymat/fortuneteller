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
    @inventory_position = InventoryPosition.new(product: self.product, location: self.location, on_hand_quantity: 0)
    if @inventory_position.save
      @inventory_position.create_projections
    end
  end

end
