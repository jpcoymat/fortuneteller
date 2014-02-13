class Forecast < MovementSource

  def steps_on_existing_order_lines?
    overlapping_order_lines.empty?
  end
  
  def overlap_quantity
    quantity = 0
    overlapping_order_lines.each {|order_line| quantity += order_line.quantity}
    return quantity
  end

  def overlapping_order_lines
    @order_lines = OrderLine.where(etd: self.etd, product_id: self.product_id, origin_location_id: self.origin_location_id).all
    @order_lines
  end  

end
