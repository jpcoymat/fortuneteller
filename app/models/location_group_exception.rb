class LocationGroupException
  include Mongoid::Document
  include Mongoid::Timestamps

  field :begin_date, type: Date
  field :end_date, type: Date
  field :aggregate_minimum, type: Float
  field :aggregate_on_hand_quantity, type: Float

  belongs_to :product
  belongs_to :location_group
  belongs_to :organization


  validates :product, :begin_date, :end_date, :aggregate_minimum, :aggregate_on_hand_quantity, presence: true



end
