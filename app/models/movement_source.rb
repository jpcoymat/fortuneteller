class MovementSource
  include Mongoid::Document
  include Mongoid::Timestamps

  #recursively_embeds_many #used for paret-child relationship
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
  field :parent_movement_source_id, type: BSON::ObjectId  

  belongs_to :organization
  belongs_to :product  

  has_many :inventory_adjustments

  before_create  :set_original_quantity  

  validates :object_reference_number, :quantity, :organization_id, :product_id, :eta, :etd, presence: true
  validates_uniqueness_of :object_reference_number, scope: :organization_id
  validate :origin_or_destination
  validate :parent_child_match
  validate :arrival_after_departure
  validate :different_locations

  def origin_location
    @origin_location = Location.where(id: self.origin_location_id).first
  end

  def destination_location
    @destination_location = Location.where(id: self.destination_location_id).first
  end
  
  def origin_location=(location)
    self.origin_location_id = location.try(:id)
  end

  def destination_location=(location)
    self.destination_location_id = location.try(:id)
  end

  def trackable?
    product_location_assignment = ProductLocationAssignment.where(product_id: self.product_id, location_id: self.origin_location_id).first
    product_location_assignment.nil? ? ProductLocationAssignment.where(product_id: self.product_id, location_id: self.destination_location_id).first : nil
    !(product_location_assignment.nil?) #if PLA is nil, return false (not trackable) and if PLA is not nil, return true (trackable)
  end  

  def parent_movement_source
    @parent_movement_source = nil
    self.parent_movement_source_id.nil? ? nil : @parent_movement_source = MovementSource.find(self.parent_movement_source_id)
    @parent_movement_source
  end

  def parent_movement_source=(movement_source)
    self.parent_movement_source_id = movement_source.id
  end
  
  def child_movement_sources
    @child_movement_sources = MovementSource.where(parent_movement_source_id: self.id).all
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

    def parent_child_match
      if parent_movement_source 
        if (parent_movement_source.product != self.product) || (parent_movement_source.origin_location != self.origin_location) || (parent_movement_source.destination_location != self.destination_location)
          errors.add(:base, "Object details does not match parent")
        end
      end
    end
    
    def arrival_after_departure
      if self.etd and self.eta
        if self.etd > self.eta
          errors.add(:base, "ETD cannot be greater than ETA") 
        end
      end 
    end

    def different_locations
      if origin_location == destination_location
        errors.add(:base, "Origin and Destination must be different")
      end
    end

end
