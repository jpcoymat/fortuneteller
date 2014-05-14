class InventoryException
  
  attr_accessor :begin_date
  attr_accessor :end_date
  attr_accessor :product
  attr_accessor :location
  attr_accessor :exception_type
  attr_accessor :priority
  attr_accessor :description

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

  def initialize
    @priority = self.priorities[@exception_type]
  end


end
