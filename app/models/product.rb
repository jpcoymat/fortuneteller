class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :code, type: String
  field :is_active, type: Boolean
 
  belongs_to :organization
  has_many :product_location_assignments


  def locations
    @locations = Location.find(self.product_location_assignments.map {|pla| pla.location_id})
  end  

end
