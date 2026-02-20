# config/initializers/open_ai.rb
OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
  config.request_timeout = ENV.fetch("OPENAI_REQUEST_TIMEOUT", "18").to_i
end
