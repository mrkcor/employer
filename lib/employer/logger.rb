module Employer
  class Logger
    attr_reader :loggers

    def initialize
      @loggers = []
    end

    def append_to(logger)
      loggers << logger
    end

    def debug(message = nil, &block)
      log(:debug, message, &block)
    end

    def error(message = nil, &block)
      log(:error, message, &block)
    end

    def warn(message = nil, &block)
      log(:warn, message, &block)
    end

    def info(message = nil, &block)
      log(:info, message, &block)
    end

    def fatal(message = nil, &block)
      log(:fatal, message, &block)
    end

    private

    def log(level, message = nil, &block)
      loggers.each do |logger|
        next unless logger.respond_to?(level)

        if message
          logger.public_send(level, message)
        elsif block
          logger.public_send(level, &block)
        end
      end
    end
  end
end
