class Location
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :code, type: String
  field :address_1, type: String
  field :address_2, type: String
  field :city, type: String
  field :state_providence, type: String
  field :country, type: String
  field :postal_code, type: String
  field :is_active, type: Boolean

  belongs_to :organization  

  validates :name, :code, :city, :country, presence: true
  validates_uniqueness_of :code, scope: :organization_id

  after_initialize :activate

  def activate
    self.is_active = true
  end

end
