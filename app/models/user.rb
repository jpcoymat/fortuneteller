class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email,              :type => String, :default => ""
  field :encrypted_password, :type => String
  field :first_name, type: String
  field :last_name, type: String
  field :dob, type: Date
  field :username, type: String

  validates :first_name, :last_name, :email, :organization_id, presence: true

  validates	:username, :length => {:within => 3..40}
  validates	:username, :first_name, :last_name, :email, :encrypted_password, :presence => true
  validates	:username, :uniqueness => true
  validates	:password, :confirmation => true
  validate 	:password_must_be_present

  belongs_to :organization

  def product_location_assignments
    @product_location_assignments = self.organization.product_location_assignments
  end

  def full_name
    self.first_name + " " + self.last_name
  end

  def password_must_be_present
    errors.add(:password, "Missing password" ) unless encrypted_password.present?
  end
 
  def password
    @password
  end  
  
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    self.hashed_password = Digest::SHA1.hexdigest(self.password)
  end

  def self.authenticate(username, password)
    user = first(:conditions => ["username = ?", username])
    unless user.nil?
      expected_password = Digest::SHA1.hexdigest(password)
      if user.encrypted_password != expected_password
        user = nil
      end
    end
    user 
  end

end
