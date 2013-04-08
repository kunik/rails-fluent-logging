require 'json-colorizer'

module RailsFluentLogging
  class JsonFormatter < JsonColorizer
    SEVERITY_COLORS = {
      'DEBUG' =>   { color: :yellow },
      'INFO' =>    { color: :cyan },
      'WARN' =>    { color: :light_magenta },
      'ERROR' =>   { color: :red },
      'FATAL' =>   { background: :red, color: :white },
      'UNKNOWN' => { color: :default }
    }

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

    def severity(s)
      colorize(s[0].upcase, SEVERITY_COLORS[s] || SEVERITY_COLORS['UNKNOWN'])
    end

    alias :call :format
  end
end