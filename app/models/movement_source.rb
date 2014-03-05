class MovementSource
  include Mongoid::Document
  include Mongoid::Timestamps
  recursively_embeds_many #used for paret-child relationship
  field :source, type: String
  field :object_reference_number, type: String
  field :original_quantity, type: Float
  field :quantity, type: Float
  field :legacy_persistance, type: Boolean
  field :eta, type: Date
  field :etd, type: Date
  field :quantity, type: Float
  field :origin_location_id, type: BSON::ObjectId
  field :destination_location_id, type: BSON::ObjectId
  field :legacy_store_id, type: String
  field :type, type: String
  
  belongs_to :organization
  belongs_to :location
  belongs_to :product  
  

  def origin_location
    @origin_location = Location.find(self.origin_location_id)
  end

  def destination_location
    @destination_location = Location.find(self.destination_location_id)
  end
  
  def origin_location=(location)
    self.origin_location_id = location.id
  end

  def destination_location=(location)
    self.destination_location_id = location.id
  end

  def trackable?
    product_location_assignment = ProductLocationAssignment.where(product_id: self.product_id, location_id: self.origin_location_id).first
    product_location_assignment.nil? ? ProductLocationAssignment.where(product_id: self.product_id, location_id: self.destination_location_id).first : nil
    !(product_location_assignment.nil?) #if PLA is nil, return false (not trackable) and if PLA is not nil, return true (trackable)
  end  

end
