class OrderLine < MovementSource
  
 
  def self.import(file_path)
    spreadsheet = open_spreadsheet(file_path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      order_line = where(object_reference_number: row["object_reference_number"]).first || new
      order_line.attributes = row
      order_line.source = "GTN"
      order_line.original_quantity = order_line.quantity
      order_line.last_shift_date = Date.today
      order_line.organization = Organization.first
      logger.debug order_line.to_json.to_s
      Resque.enqueue(SourceProcessingJob, order_line.to_json) if order_line.valid?
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

end
