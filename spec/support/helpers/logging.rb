module Helpers
  module Logging
    # Allow collecting the logs produced by the Rails.logger
    # on the block yielded.
    #
    # The logs produced while the block is executed are
    # returned afterwards, so could be used for testing
    # purposes.
    #
    # @example
    #
    # logs = capture_logs do
    #   # Run some code that uses Rails.logger.
    # end
    def capture_logs
      original_logger = Rails.logger

      logs = []

      Rails.logger = ActiveSupport::TaggedLogging.new(
        Logger.new(StringIO.new)
      )
      Rails.logger.instance_variable_set(
        :@logdev,
        ActiveSupport::Logger::LogDevice.new(StringIO.new)
      )
      Rails.logger.formatter = proc do |*_, msg|
        logs << msg

        "#{msg}\n"
      end

      yield

      logs
    ensure
      Rails.logger = original_logger
    end
  end
end
