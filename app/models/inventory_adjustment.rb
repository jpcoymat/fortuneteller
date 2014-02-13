class InventoryAdjustment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :source, type: String
  field :adjustment_action, type: String
  field :adjustment_quantity, type: Float
  field :adjustment_date, type: Date
  field :object_reference_number, type: String 
  field :legacy_store_id, type: String
  field :type, type: String
  field :legacy_persistance, type: Boolean

  belongs_to :organization
  belongs_to :location
  belongs_to :product

end
