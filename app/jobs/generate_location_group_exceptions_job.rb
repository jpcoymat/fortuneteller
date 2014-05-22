class GenerateLocationGroupExceptionsJob 

  @queue = :inventory_exceptions
 
  def self.perform
    cleanup
    start_date = Date.today
    end_date = start_date + Organization.first.days_to_project.days
    Product.each do |product|
      LocationGroup.each do |location_group|
        (start_date .. end_date).each do |current_date|
          location_group_exception = LocationGroupException.new
          location_group_exception.organization =  Organization.first
          location_group_exception.product = product
          location_group_exception.aggregate_minimum = 0
          location_group_exception.aggregate_on_hand_quantity = 0
          location_group_exception.location_group = location_group
          location_group_exception.begin_date = current_date
          location_group_exception.end_date = current_date
          location_array =  Location.where(location_group: location_group).map {|loc| loc.id}
          InventoryPosition.where(product: product).in(location_id: location_array).each do |inventory_position|
             location_group_exception.aggregate_on_hand_quantity += inventory_position.inventory_projections.where(projected_for: current_date).first.try(:on_hand_quantity) || 0
             location_group_exception.aggregate_minimum += inventory_position.product_location_assignment.try(:minimum_quantity) || 0
          end
          location_group_exception.save if location_group_exception.aggregate_on_hand_quantity < location_group_exception.aggregate_minimum 
        end
      end
    end
    regroup
  end

  def self.cleanup
    LocationGroupException.each {|lge| lge.destroy}
  end

  def self.regroup
    LocationGroupException.distinct(:location_group_id).each do |location_group_id|
      LocationGroupException.where(location_group_id: location_group_id).distinct(:product_id).each do |product_id|
        grouped_exceptions = LocationGroupException.where(location_group_id: location_group_id, product_id: product_id).order_by("begin_date ASC").all
        adjacent_exception = []
        starting_point = grouped_exceptions.first
        stopping_point = grouped_exceptions.first
        for i in (1 .. grouped_exceptions.count-1)
          if (grouped_exceptions[i].end_date - grouped_exceptions[i-1].end_date).to_i*86400 > 1.day
            starting_point.end_date = stopping_point.end_date
            starting_point.save
            starting_point = grouped_exceptions[i] 
            stopping_point = grouped_exceptions[i] 
          else
            stopping_point = grouped_exceptions[i]
            adjacent_exception << grouped_exceptions[i]
          end
        end
        starting_point.end_date = stopping_point.end_date
        starting_point.save
        adjacent_exception.each {|loc_group_exception| loc_group_exception.destroy}
      end
    end
  end



end

