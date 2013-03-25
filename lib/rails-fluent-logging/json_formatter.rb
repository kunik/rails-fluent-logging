require 'json-colorizer'

module RailsFluentLogging
  class JsonFormatter < JsonColorizer
    def initialize(schema, datetime_format)
      super(schema)
      @datetime_format = datetime_format
    end

    def datetime(d)
      d.strftime(@datetime_format)
    end

    def message(s)
      s.to_s
    end

    alias :call :format
  end
end