class InventoryPosition
  include Mongoid::Document
  include Mongoid::Timestamps
  field :on_hand_quantity,	type: Float

  embeds_many :inventory_projections, order: :projected_for.asc 

  belongs_to :product
  belongs_to :location

  def latest_projection_date
    self.inventory_projections.last.projected_for
  end

  def create_projections
    if self.inventory_projections.empty?
      days_to_project = self.location.organization.days_to_project
      projection_date = Date.today
      days_to_project.times do 
        inventory_projection = self.inventory_projections.new(projected_for: projection_date)
        inventory_projection.calculate_on_hand_quantity
        inventory_projection.set_all_fields
        projection_date += 1.day
      end
      self.save
    end
  end   
 
  def projection_aggregate(inventory_bucket)
    inventory_bucket_total = 0
    self.inventory_projections.each {|projection| inventory_bucket_total += projection.attributes[inventory_bucket]} if self.inventory_projections.first.has_key?(inventory_bucket) 
    inventory_bucket_total
  end

  def product_location_assignment
    @product_location_assignment = ProductLocationAssignment.where(product: self.product, location: self.location).first
  end


  def on_order_quantity
    @on_order_quantity = projection_aggregate("on_order_quantity")
  end


  def forecasted_quantity
    @forecasted_quantity = projection_aggregate("forecasted_quantity")
  end

  def in_transit_quantity
    @in_transit_quantity = projection_aggregate("in_transit_quantity")
  end

  def allocated_quantity
    @allocated_quantity = projection_aggregate("allocated_quantity")
  end

  def available_quantity
    self.on_hand_quantity + on_order_quantity + in_transit_quantity - allocated_quantity - forecasted_quantity
  end

  def reset_projections
    unless self.inventory_projections.empty?
      self.inventory_projections.each do |projection|
        projection.calculate_on_hand_quantity
        projection.set_all_fields
      end
      self.save
    end
  end

  def crawl
    today = Date.today
    self.inventory_projections.where(:projected_for.lt => today).each {|projection| projection.destroy}
    self.save
    reset_projections
    while self.inventory_projections.count <= self.product.organization.days_to_project
      latest_date = self.inventory_projections.last.projected_for
      new_date = latest_date + 1.day
      inventory_projection = self.inventory_projections.new(projected_for: new_date)
      inventory_projection.calculate_on_hand_quantity
      inventory_projection.set_all_fields
      self.save
    end
  end

  def unfulfilled_demand_projections
    self.inventory_projections.where(:on_hand_quantity.lt => 0).all
  end
  
  def max_exceeded_projections
    self.inventory_projections.where(:on_hand_quantity.gt => product_location_assignment.maximum_quantity).all 
  end

  def below_min_projections
   self.inventory_projections.where(:on_hand_quantity.lt => product_location_assignment.minimum_quantity, :on_hand_quantity.gte => 0).all
  end
  

  def generate_inventory_exceptions
    InventoryException.create_from_projections(unfulfilled_demand_projections, "Unfulfilled Demand") if unfulfilled_demand_projections.count > 0
    InventoryException.create_from_projections(max_exceeded_projections, "Max Exceeded") if max_exceeded_projections.count > 0
    InventoryException.create_from_projections(below_min_projections, "Below Min") if below_min_projections.count > 0
  end

  def product_name
    self.product.try(:name)
  end

  def product_name=(name)
    self.product_id = Product.where(name: name).first.id
  end


end
