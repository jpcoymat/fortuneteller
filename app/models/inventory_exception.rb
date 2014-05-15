class InventoryException
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :begin_date, type: Date
  field :end_date, type: Date
  field :exception_type, type: String
  field :priority, type: Integer
  field :description, type: String

  belongs_to :product
  belongs_to :location

  validates :product, :location, :begin_date, :end_date, :priority, :exception_type, presence: true

  before_create :set_priority

  def total_days
    @total_days = (@end_date - @begin_date).to_i    
  end
   
 
  def generate_description
    @description = "Product " + @product.name + " will be out of stock for " + total_days.to_s + " days at location " + @location.name
  end  

  def self.exception_types
    ["Max Exceeded", "Below Min", "Unfulfilled Demand"]
  end

  def self.priorities
    {"Max Exceeded" => 3, "Below Min" => 2, "Unfulfilled Demand" => 1}
  end


  def self.create_from_projections(projections, exception_type)
    start_date = projections.first.projected_for
    end_date = projections.first.projected_for
    location = projections.first.inventory_position.location
    product = projections.first.inventory_position.product
    for i in (1 .. projections.count-1)
      if projections[i].projected_for - projections[i-1].projected_for > 1.day
         inventory_exception = InventoryException.new(exception_type: exception_type)
         inventory_exception.begin_date = start_date
         inventory_exception.end_date = end_date
         inventory_exception.location = location
         inventory_exception.product = product 
         inventory_exception.save_priority 
	 inventory_exception.save 
         start_date =  projections[i].projected_for
      else
        end_date = projections[i].projected_for  
      end 
    end
    inventory_exception = InventoryException.new(exception_type: exception_type, begin_date: start_date, end_date: end_date, location: location, product: product)  
    inventory_exception.set_priority
    inventory_exception.save
  end

    
  def set_priority
    self.priority = self.class.priorities[self.exception_type]
  end

end
