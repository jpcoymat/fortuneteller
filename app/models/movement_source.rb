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
  
  belongs_to :organization
  belongs_to :product  

  before_create  :set_original_quantity  

  validates :object_reference_number, :quantity, presence: true
  validate :origin_or_destination

  def origin_location
    @origin_location = Location.where(id: self.origin_location_id).first
  end

  def destination_location
    @destination_location = Location.where(id: self.destination_location_id).first
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

  protected

    def set_original_quantity
      self.original_quantity = self.quantity
    end 

    def origin_or_destination
      if self.origin_location_id.nil? and self.destination_location_id.nil?
        errors.add(:base, "Origin and Destination cannot be both null") 
      end
    end
    
   

end
