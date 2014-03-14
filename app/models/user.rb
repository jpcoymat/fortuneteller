class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email,              :type => String, :default => ""
  field :encrypted_password, :type => String
  field :first_name, type: String
  field :last_name, type: String
  field :dob, type: Date

  validates :first_name, :last_name, :email, :organization_id, presence: true
  belongs_to :organization

  def product_location_assignments
    @product_location_assignments = self.organization.product_location_assignments
  end

end
