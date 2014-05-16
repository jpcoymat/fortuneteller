class GenerateExceptionsJob

  @queue = :inventory_exceptions

  def self.perform
    Resque.logger.info("Starting Inventory Exception process")
    InventoryException.all.destroy
    InventoryPosition.all.each {|ip| ip.generate_inventory_exceptions}
    Resque.logger.info("Inventory Exception Process completed")
  end

end
