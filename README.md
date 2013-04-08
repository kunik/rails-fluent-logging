#Installation

1. Add to your `Gemfile`

    gem 'rails-fluent-logging', git: 'git@github.com:kunik/rails-fluent-logging.git'

2. Add to your `config/application.rb`

    config.logger = RailsFluentLogging::Logger.default
    config.colorize_logging = false

    # Middleware configuration
    config.middleware.swap(Rails::Rack::Logger, RailsFluentLogging::Middleware, config.log_tags)

3. Add to your `config/initializers/fluent_logging.rb`

    RailsFluentLogging::LogDevice.configure do |config|
      config[:uri] = ENV['FLUENT_URI']
      config[:level] = Rails.configuration.log_level
    end

