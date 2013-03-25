require 'rails/rack/logger'

module FluentLogging
  class Middleware < Rails::Rack::Logger
    protected
      def compute_tags(request)
        @taggers.collect do |tag|
          case tag
          when Proc
            Hash[tag.to_s, tag.call(request)]
          when Symbol
            Hash[tag, request.send(tag)]
          when Hash
            tag
          else
            Hash[tag.to_s, tag]
          end
        end
      end
  end
end
