require 'resque'
require 'resque_scheduler'
redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"] || 'localhost:6379'
uri = URI.parse(redis_url)
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
Resque.schedule = YAML.load_file(File.join(Rails.root, 'config/resque_schedule.yml'))
