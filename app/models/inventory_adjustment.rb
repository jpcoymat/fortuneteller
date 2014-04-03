class InventoryAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :source, type: String
  field :adjustment_type, type: String
  field :adjustment_quantity, type: Float
  field :adjustment_date, type: Date
  field :object_reference_number, type: String 
  field :legacy_store_id, type: String
  field :legacy_persistance, type: Boolean

  belongs_to :organization
  belongs_to :location
  belongs_to :product
  belongs_to :movement_source

  validates :object_reference_number, :organization_id, :location_id, :product_id, :adjustment_quantity, presence: true
  validates_uniqueness_of :object_reference_number, scope: :organization_id


end
