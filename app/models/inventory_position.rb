class InventoryPosition
  include Mongoid::Document
  include Mongoid::Timestamps
  field :on_hand_quantity,	type: Float

  embeds_many :inventory_projections, order: :projected_for.asc 

  belongs_to :product
  belongs_to :location

  def add_movement_source(movement_source)
    if movement_source_within_projection?(movement_source)
      case movement_source.class.name 
        when "Forecast"
          add_forecast(movement_source)
        when "OrderLine"
          add_order_line(movement_source)
        when "ShipLine"
          add_ship_line(movement_source)
      end
    end 
  end

  def movement_source_within_projection?(movement_source)
    @movement_source.projected_for <= latest_projection_date
  end

  def latest_projection_date
    self.inventory_projections.last.projected_for
  end

  def add_forecast(forecast)
    self.on_order_qty += forecast.quantity
    
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
 
  def on_order_quantity
    @on_order_quantity = 0
    self.inventory_projections.each {|projection| @on_order_quantity += projection.on_order_quantity}
    @on_order_quantity	
  end


  def forecasted_quantity
    @forecasted_quantity = 0
    self.inventory_projections.each {|projection| @forecasted_quantity += projection.forecasted_quantity}
    @forecasted_quantity
  end

  def in_transit_quantity
    @in_transit_quantity = 0
    self.inventory_projections.each {|projection| @in_transit_quantity += projection.in_transit_quantity}
    @in_transit_quantity
  end

  def allocated_quantity
    @allocated_quantity = 0
    self.inventory_projections.each {|projection| @allocated_quantity += projection.allocated_quantity}
    @allocated_quantity
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
    while self.inventory_projections.count < self.product.organization.days_to_project
      latest_date = self.inventory_projections.last.projected_for
      new_date = latest_date + 1.day
      inventory_projection = self.inventory_projections.new(projected_for: new_date)
      inventory_projection.calculate_on_hand_quantity
      inventory_projection.set_all_fields
      self.save
    end
  end


end
