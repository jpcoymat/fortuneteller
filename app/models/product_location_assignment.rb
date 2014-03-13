class ProductLocationAssignment
  include Mongoid::Document
  include Mongoid::Timestamps  
  field :minimum_quantity, type: Integer
  field :maximum_quantity, type: Integer 
  field :is_active, type: Boolean

  belongs_to :product
  belongs_to :location

  validates :product_id, uniqueness: {scope: :location_id}

end
