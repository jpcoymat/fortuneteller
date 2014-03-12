class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :address_1, type: String
  field :city, type: String
  field :organization_type, type: String
  field :days_to_project, type: Integer
  
  has_many :users
  has_many :products
  has_many :locations

end
