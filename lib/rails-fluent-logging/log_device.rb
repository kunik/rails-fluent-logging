require 'fluent-logger'
require File.expand_path('json_formatter', File.dirname(__FILE__))

module RailsFluentLogging
  class LogDevice
    SEVERITY_MAP = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN)

    class << self
      def configure
        yield(config)
        reconfigure!
      end

      def config
        @config ||= {
          app_name: 'rails_app',
          host: nil,
          port: 24224,
          level: :debug,
          debug: false,
          datetime_format: '%d/%m/%y %H:%M:%S.%L',
          log_schema: {
            datetime: [ :datetime, :green ],
            severity: [ :severity ],
            tags: [
              lambda do |item|
                parts = %W([#{item[:pid]}:#{item[:uuid]}])

                if item[:user_id]
                  parts << %(U##{item[:user_id]})
                end

                other = item.reject {|k, _| [:pid, :uuid, :user_id].include?(k)}
                unless other.empty?
                  parts << other.to_s
                end

                parts.join(' ')
              end,
              :white
            ],
            message: :message,
            _other: true
          }
        }
      end

      def all_instances
        @all_instances ||= []
      end

      protected
        def reconfigure!
          all_instances.each(&:reconfigure!)
        end
    end

    def initialize
      self.class.all_instances << self
      reconfigure!
    end

    def silence(*args) end

    def add(severity, tags, message, progname, &block)
      return true if severity < level

      log_entity = apply_formatting({
        severity: SEVERITY_MAP[severity] || SEVERITY_MAP.last,
        tags: make_hash(tags),
        message: (String === message ? message : message.inspect)
      })

      post_to_fluentd(severity, log_entity) or fallback_log << "#{log_entity}\n"
    end

    def method_missing(method, *args)
      fallback_log.send(method, *args)
    end

    def reconfigure!
      clear_options!
    end

    private
      def apply_formatting(entity)
        entity[:datetime] = Time.now.utc
        json_formatter.call(entity)
      end

      def post_to_fluentd(severity, data)
        fluentd_connection_configured? && fluentd_client.post(severity, data)
      end

      def clear_options!
        @options = nil
        @level = nil
        @fallback_log = nil
        @fluentd_client = nil
        @json_formatter = nil
        @fluentd_connection_configured = nil
      end

      def fluentd_connection_configured?
        if !defined?(@fluentd_connection_configured) || @fluentd_connection_configured.nil?
          @fluentd_connection_configured = !(options[:host].nil? || options[:host].empty?)
        end

        @fluentd_connection_configured
      end

      def options
        @options ||= {}.merge(self.class.config).tap do |options|
          if options[:uri]
            uri = URI.parse options[:uri]

            options[:host] = uri.host
            options[:port] = uri.port
            options[:app_name] = uri.path.sub(/\A\/+/, '').gsub(/\/+/, '.')
          end
        end
      end

      def level
        @level ||= ::Logger.const_get(options[:level].to_s.upcase.to_sym)
      end

      def fluentd_client
        @fluentd_client ||= Fluent::Logger::FluentLogger.open(options[:app_name], options)
      end

      def json_formatter
        @json_formatter ||= JsonFormatter.new(options[:log_schema], options[:datetime_format])
      end

      def fallback_log
        @fallback_log ||= ::Logger.new($stdout)
      end

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
  end
end

