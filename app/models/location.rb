class Location
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :code, type: String
  field :address_1, type: String
  field :address_2, type: String
  field :city, type: String
  field :state_providence, type: String
  field :country, type: String
  field :postal_code, type: String
  field :is_active, type: Boolean
  field :latitude,  type: Float
  field :longitude,  type: Float
  field :shipping_capacity, type: Float
  field :receiving_capacity, type: Float
  field :warehousing_capacity, type: Float

  belongs_to :organization  
  belongs_to :location_group

  validates :name, :code, :city, :country, presence: true
  validates_uniqueness_of :code, scope: :organization_id
  has_many :inventory_positions
  has_many :product_location_assignments
  has_many :inventory_exceptions
  after_initialize :activate

  def activate
    self.is_active = true
  end

  def grouped_exception_counts
    @grouped_exception = {}
    InventoryException.priorities.each {|k,v| @grouped_exception[v] = self.inventory_exceptions.where(priority: v).count}
    @grouped_exception
  end


  def aggregate_quantity(inventory_bucket)
    total_quantity = 0
    self.inventory_positions.each do |position|
      if inventory_bucket == "on_hand_quantity"  
        total_quantity += position.on_hand_quantity 
      else
        total_quantity += position.projection_aggregate(inventory_bucket)
      end 
    end
    total_quantity	
  end
  
  def carrying_capacity
    @carrying_capacity = 0
    self.product_location_assignments {|pla| @carrying_capacity += pla.maximum_quantity}
    @carrying_capacity
  end

end
