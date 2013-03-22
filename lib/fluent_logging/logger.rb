require 'active_support/tagged_logging'

module FluentLogging
  class Logger < ActiveSupport::TaggedLogging
    class << self
      def default
        self.new(LogDevice.new)
      end
    end

    def add(severity, message = nil, progname = nil, &block)
      message = (block_given? ? block.call : progname) if message.nil?
      @logger.add(severity, current_tags, message, progname)
    end

    def bug(ticket, progname=nil, &block)
      tagged(ticket: ticket) { debug(progname, &block) }
    end
  end
end
