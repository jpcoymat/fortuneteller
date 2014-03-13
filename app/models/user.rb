class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :username, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :dob, type: Date

  belongs_to :organization

  def product_location_assignments
    @product_location_assignments = self.organization.product_location_assignments
  end

end
