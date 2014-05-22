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
  has_many :movement_sources
  has_many :location_groups
  has_many :location_group_exceptions  

  def product_location_assignments
    @product_location_assignments = []
    self.products.each {|product| @product_location_assignments << product.product_location_assignments}
    @product_location_assignments.flatten!
    @product_location_assignments
  end

  def forecasts
    @forecasts = Forecast.where(organziation_id: self.id).all
  end

  def order_lines
    @order_lines = OrderLine.where(organization_id: self.id).all
  end

  def ship_lines
    @ship_lines = ShipLine.where(organization_id: self.id).all
  end 

end
