class LocationGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :code, type: String
  field :name, type: String

  belongs_to :organization
  has_many :locations

  validates :code, :name, presence: true
  validates :name, uniqueness: {scope: :organization_id}
  validates :code, uniqueness: {scope: :organization_id}

end
