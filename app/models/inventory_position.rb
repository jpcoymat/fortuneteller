class InventoryPosition
  include Mongoid::Document
  include Mongoid::Timestamps
  field :on_hand_quantity,	type: Float
  field :allocated_quantity,	type: Float
  field :in_transit_quantity,	type: Float
  field :on_order_quantity,	type: Float
  field :forecasted_quantity,	type: Float

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
        inventory_projection = InventoryProjection.new(projected_for: projection_date)
        inventory_projection.calculate_on_hand_quantity
        inventory_projection.set_all_fields
        self.create_inventory_projection(inventory_projection)
        projection_date += 1.day
      end
    end
  end   

end
