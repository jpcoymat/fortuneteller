class OrdersReset
  
  @queue = :reset_data   

  def self.clean_slate
    MovementSource.delete_all
    InventoryAdjustment.delete_all
    InventoryPosition.where(:on_hand_quantity.lte => 0). each do |ip|
      ip.on_hand_quantity =rand(500..750).to_i
      ip.save
      ip.reset_projections
    end
    InventoryPosition.where(:on_hand_quantity.gt => 0).each {|ip| ip.reset_projections}
  end

  def self.perform
    clean_slate
    setup_data.each do |prod_time|
      create_orders(prod_time["product"], prod_time["location"], prod_time["lead_time"], prod_time["target_quantity"], prod_time["days_to_target"], prod_time["forecast_switch"])
    end
  end   

  def self.create_orders(product, location, lead_time, target_quantity, days_to_target, forecast_switch)
    current_date = Date.today
    end_date = current_date + 59.days
    ip = InventoryPosition.where(product: product, location: location).first
    target_date = Date.today + days_to_target.days
    daily_change_quantity = ((target_quantity - ip.on_hand_quantity)/days_to_target).to_i
    recovery_quantity = ((ip.on_hand_quantity - target_quantity)/(60 - days_to_target)).to_i
    forecast_switch_date = Date.today + forecast_switch.days
    while current_date < end_date
      order_qty = rand(125..155)
      current_date < target_date ? alloc_qty = order_qty - daily_change_quantity : alloc_qty = order_qty - recovery_quantity
      alloc_qty += rand(-8..8)
      ref_number = "OL" + (rand()*1000000).floor.to_s.rjust(7,"0") 
      inbound_order = OrderLine.new(source: "GTN", object_reference_number: ref_number, original_quantity: order_qty, quantity: order_qty, eta: current_date, etd: (current_date - lead_time.days), origin_location_id: nil, destination_location_id: location.id, product_id: product.id, organization_id: product.organization.id)
      if inbound_order.valid?
        if current_date < forecast_switch_date
          ref_number = "OL" + (rand()*1000000).floor.to_s.rjust(7,"0")   
	  alloc_source = OrderLine.new(source: "GTN", object_reference_number: ref_number, original_quantity: alloc_qty, quantity: alloc_qty, etd: current_date, eta: (current_date + lead_time.days), origin_location_id: location.id, destination_location_id: nil, product_id: product.id, organization_id: product.organization.id)  
        else
          ref_number = "FC" + (rand()*1000000).floor.to_s.rjust(7,"0")   
	  alloc_source = Forecast.new(source: "GTN", object_reference_number: ref_number, original_quantity: alloc_qty, quantity: alloc_qty, etd: current_date, eta: current_date, origin_location_id: location.id, destination_location_id: nil, product_id: product.id, organization_id: product.organization.id)  
        end	
        if alloc_source.valid?
	  Resque.enqueue(SourceProcessingJob, inbound_order.to_json)
	  Resque.enqueue(SourceProcessingJob, alloc_source.to_json)
	  current_date += 1.day
        end	
      end
    end
  end
    
  def self.setup_data
    [ {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Warehouse 1").first, "target_quantity" => -90, "days_to_target"=> 20,"lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Warehouse 2").first, "target_quantity" => -145, "days_to_target" => 25, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Warehouse 3").first, "target_quantity" => 1250, "days_to_target"=> 10, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Warehouse 4").first,"target_quantity" => -85, "days_to_target" => 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Zaragoza").first, "target_quantity" => 410, "days_to_target" => 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUA001").first, "location" => Location.where(name: "Taipei").first, "target_quantity" => 765, "days_to_target" => 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Warehouse 1").first, "target_quantity" => -120, "days_to_target"=> 20, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Warehouse 2").first, "target_quantity" => 1000, "days_to_target"=> 25, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Warehouse 3").first, "target_quantity" => -115, "days_to_target"=> 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Warehouse 4").first, "target_quantity" => 50, "days_to_target"=> 10, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Zaragoza").first, "target_quantity" => 300, "days_to_target"=> 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUB001").first, "location" => Location.where(name: "Taipei").first, "target_quantity" => 500, "days_to_target"=> 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Warehouse 1").first, "target_quantity" => -100, "days_to_target"=> 22, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Warehouse 2").first, "target_quantity" => 80, "days_to_target"=> 15, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Warehouse 3").first, "target_quantity" => -100,"days_to_target"=> 20, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Warehouse 4").first, "target_quantity" => 50, "days_to_target"=> 20, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Zaragoza").first, "target_quantity" => 400, "days_to_target"=> 600, "lead_time"=> 7, "forecast_switch" => 30},
      {"product" => Product.where(name: "SKUC001").first, "location" => Location.where(name: "Taipei").first,"target_quantity" => 810, "days_to_target"=> 600, "lead_time"=> 7, "forecast_switch" => 30}
    ]
  end
  
  
end  
