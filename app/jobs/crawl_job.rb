class CrawlJob

  @queue = :crawl

  def self.perform
    InventoryPosition.all.each {|ip| ip.crawl}
  end


end
