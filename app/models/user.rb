class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :username, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :dob, type: Date

  belongs_to :organization
end
