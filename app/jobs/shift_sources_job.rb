class ShiftSourcesJob
  @queue = :reset_data
  
  def self.crawl
    CrawlJob.perform
  end
  
  def self.shift
    MovementSource.all.each do |movement_source|
	  movement_source.etd += 1.day
      movement_source.eta += 1.day
      Resque.enqueue(SourceProcessingJob, movement_source.to_json)	  
	end
  end

  def self.perform
    crawl
	shift
  end
  
end
