class ProductLocationAssignment
  include Mongoid::Document
  include Mongoid::Timestamps  
  field :minimum_quantity, type: Integer
  field :maximum_quantity, type: Integer 

  belongs_to :product
  belongs_to :location

end
