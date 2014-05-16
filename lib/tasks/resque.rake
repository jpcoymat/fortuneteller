require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" => :environment do
  Resque.before_fork = Proc.new { 
    logfile = File.open(File.join(Rails.root, 'log', 'resque.log'), 'a')
    logfile.sync = true
    Resque.logger = Logger.new(logfile)
    Resque.logger.level = Logger::INFO
    Resque.logger.info "Resque Logger Initialized!"
  }
end
