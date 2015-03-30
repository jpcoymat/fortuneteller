class ShipLine < MovementSource 

  before_create  :set_etd

  def self.import(file_path)
    spreadsheet = open_spreadsheet(file_path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      ship_line= where(object_reference_number: row["object_reference_number"]).first || new
      ship_line.attributes = row
      order_line = OrderLine.where(object_reference_number: row["order_line_number"]).first
      ship_line.product_id = order_line.try(:product_id)
      ship_line.origin_location_id = order_line.try(:origin_location_id)
      ship_line.destination_location_id = order_line.try(:destination_location_id)
      ship_line.etd = Date.today
      ship_line.source = "GTN"
      ship_line.original_quantity = ship_line.quantity
      ship_line.last_shift_date = Date.today
      ship_line.organization = Organization.first
      logger.debug ship_line.to_json.to_s
      Resque.enqueue(SourceProcessingJob, ship_line.to_json) if ship_line.valid?
      logger.debug ship_line.errors.to_s if ship_line.errors
    end
  end

  def self.open_spreadsheet(file_path)
    case File.extname(file_path)
      when ".csv"
        Roo::CSV.new(file_path)
      when ".xls"
        Roo::Excel.new(file_path)
      when ".xlsx"
        Roo::Excelx.new(file_path)
      else raise "Unknown file type: #{file.original_filename}"
    end
  end


  def parent_movement_source_object_reference_number
    self.parent_movement_source.try(:object_reference_number)
  end

  def parent_movement_source_object_reference_number=(ref_number)
    self.parent_movement_source = OrderLine.where(object_reference_number: ref_number).first
  end

  def set_etd
    self.etd = Date.today
  end

  def create_shipment_confirmation
    @shipment_confirmation = ShipmentConfirmation.new(organization: self.organization, source: self.source, product: self.product, location: self.origin_location, adjustment_quantity: self.quantity, adjustment_date: self.etd, movement_source: self)
    @shipment_confirmation   
  end

  def order_line_number
    parent_movement_source_object_reference_number
  end

  def order_line_number=(ref_number)
    self.parent_movement_source = OrderLine.where(object_reference_number: ref_number).first  
  end
 

end
