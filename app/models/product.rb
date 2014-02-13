class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :code, type: String

  belongs_to :organization
  has_many :product_location_assignments


  def locations
    @locations = Location.find(self.product_location_assignments.maps {|pla| pla.location_id})
  end  

end
