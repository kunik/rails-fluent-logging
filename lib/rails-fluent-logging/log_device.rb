require 'fluent-logger'

module RailsFluentLogging
  class LogDevice
    SEVERITY_MAP = ['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL', 'UNKNOWN']
    class << self
      def configure
        yield(config)
        @configured = true
      end

      def configured?
        !!@configured
      end

      def config
        @config ||= {
          app_name: 'rails_app',
          host: '127.0.0.1',
          port: 24224,
          fallback_logger_level: :INFO
        }
      end
    end

    def silence(*args); end

    def add(severity, tags, message, progname, &block)
      message = (String === message ? message : message.inspect)
      tags = make_hash(tags)

      unless post_to_fluentd(severity, {severity: SEVERITY_MAP[severity], tags: tags, message: message})
        fallback_log.add(severity, "#{tags.to_s} #{message}", progname, &block)
      end
    end

    def formatter=(formatter)
      fallback_log.formatter = formatter
    end

    def method_missing(method, *args)
      fallback_log.send(method, *args)
    end

    private
      def make_hash(tags)
        {}.tap do |tags_hash|
          tags.each_with_index do |tag, i|
            if tag.is_a? Hash
              tags_hash.merge!(tag)
            else
              tags_hash[i] = tag
            end
          end
        end
      end

      def post_to_fluentd(severity, data)
        return false unless configured?
        fluentd_client.post(severity, data)
      end

      def configured?
        self.class.configured?
      end

      def fluentd_client
        @fluentd_client ||= create_fluentd_client
      end

      def create_fluentd_client
        if options[:fallback_logger_level]
          fallback_log.level = ::Logger.const_get(options[:fallback_logger_level])
        end

        Fluent::Logger::FluentLogger.open(options[:app_name], options)
      end

      def options
        @options ||= { logger: fallback_log }.merge(self.class.config).tap do |options|
          if options[:uri]
            uri = URI.parse options[:uri]

            options[:host] = uri.host
            options[:port] = uri.port
            options[:app_name] = uri.path.sub(/\A\/+/, '').gsub(/\/+/, '.')
          end
        end
      end

      def fallback_log
        @fallback_log ||= ::Logger.new(STDERR)
      end
  end
end

