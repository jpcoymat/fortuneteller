class OrderLine < MovementSource
  
 
  def decrease_forecast
    @forecast = Forecast.where(projected_date: self.projected_date, origin_location_id: self.origin_location_id, product_id: self.product_id).first
    unless @forecast.nil?
      @forecast.quantity -= self.quantity
      @forecast.save
    end
  end

end
