class ShiftSourcesJob
  @queue = :reset_data
  
  def self.crawl
    CrawlJob.perform
  end
  
  def self.shift
    today = Date.today
    MovementSource.all.each do |movement_source|
      if movement_source.last_shift_date < today
        movement_source.etd += 1.day
        movement_source.eta += 1.day
        movement_source.last_shift_date = today
        Resque.enqueue(SourceProcessingJob, movement_source.to_json)	  
      end
    end
  end

  def self.perform
    crawl
    shift
  end
  
end
