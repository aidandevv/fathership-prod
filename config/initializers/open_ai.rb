# config/initializers/open_ai.rb
OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.request_timeout = 240
  end