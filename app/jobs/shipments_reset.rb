class ShipmenstReset

  @queue = :reset_data 

  def self.create_ship_line_from_order_line(order_line, portion_shipped)
    ship_quantity = (order_line.quantity*portion_shipped).to_i
    ref_number = "SL" + (rand()*1000000).floor.to_s.rjust(7,"0")
    sl = ShipLine.new(organization: order_line.organization, etd: Date.today, eta: order_line.eta, product: order_line.product, origin_location: order_line.origin_location, destination_location: order_line.destination_location, quantity: ship_quantity, original_quantity: ship_quantity, source: "GTN", object_reference_number: ref_number, parent_movement_source: order_line)
    Resque.enqueue(SourceProcessingJob, sl.to_json) if sl.valid?
  end

  def self.ship_out_orders(product, location, lead_time) 
    OrderLine.where(product_id: product.id, destination_location_id: location.id, origin_location_id: nil, :eta.lte => (Date.today + lead_time.days)).each do |ol|
      create_ship_line_from_order_line(ol,1)  
    end
  end
 
  def self.partial_ship(product, location, start_range, end_date)
    start_date = Date.today + start_range.days
    end_date = start_date + end_date.days
    OrderLine.where(product_id: product.id, destination_location_id: location.id, origin_location_id: nil, :eta.gt => start_date, :eta.lte => end_date).each do |order_line|
      create_ship_line_from_order_line(order_line, rand(0.4..0.6))
    end 
  end
 
  def self.products_and_leadtime
    [ {"product" => Product.where(name: "SKUA001").first, "lead_time" => 7, "partial_ship_days" => 7},
      {"product" => Product.where(name: "SKUB001").first, "lead_time" => 7, "partial_ship_days" => 7},
      {"product" => Product.where(name: "SKUC001").first, "lead_time" => 7, "partial_ship_days" => 7}
    ]
  end
  
  def self.perform
    Location.all.each do |location|
      products_and_leadtime.each do |product_and_lead_time|
        ship_out_orders(product_and_lead_time["product"], location, product_and_lead_time["lead_time"])    
        partial_ship(product_and_lead_time["product"], location, product_and_lead_time["lead_time"], product_and_lead_time["partial_ship_days"])
      end
    end
  end
  
end

