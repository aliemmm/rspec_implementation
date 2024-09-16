module FeatureFlagsHelper
  VALID_STATUSES = %w[enabled disabled].freeze

  def with_feature_flag(feature_flag, status: :enabled)
    ensure_valid_status!(status)
    previously_enabled = Flipper.enabled?(feature_flag)

    toggle_feature_flag(feature_flag, should_enable?(status))

    yield if block_given?
  ensure
    toggle_feature_flag(feature_flag, previously_enabled) if defined?(previously_enabled)
  end

  private

  def should_enable?(status)
    status.to_s.downcase === "enabled"
  end

  def toggle_feature_flag(feature_flag, enabled)
    if enabled
      Flipper.enable(feature_flag)
    else
      Flipper.disable(feature_flag)
    end
  end

  def ensure_valid_status!(status)
    return if status.to_s.in?(VALID_STATUSES)

    raise ArgumentError, "Status must be one of #{VALID_STATUSES}"
  end
end
