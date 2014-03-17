class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :code, type: String
  field :is_active, type: Boolean, default: true
  field :product_category, type: String
 
  belongs_to :organization
  has_many :product_location_assignments

  validates :name, :code, :organization_id, presence: true
  validates_uniqueness_of :code, scope: :organization_id

  after_initialize :activate

  def activate
    self.is_active = true
  end

  def locations
    @locations = Location.find(self.product_location_assignments.map {|pla| pla.location_id})
  end  

end
