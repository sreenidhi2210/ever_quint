class ReportUtilizationValidator < ApiValidation
  attr_accessor :from, :to

  validates :from, presence: { message: "from is required" }
  validates :to, presence: { message: "to is required" }
  validate :from_must_be_iso8601
  validate :to_must_be_iso8601
  validate :from_must_be_before_to

  private

  def from_must_be_iso8601
    validate_iso8601(:from, from)
  end

  def to_must_be_iso8601
    validate_iso8601(:to, to)
  end

  def from_must_be_before_to
    return if from.blank? || to.blank?
    return unless errors[:from].blank? && errors[:to].blank?

    from_time = Time.iso8601(from.to_s)
    to_time = Time.iso8601(to.to_s)

    if from_time >= to_time
      errors.add(:from, "from must be before to")
    end
  rescue ArgumentError
    nil
  end

  def validate_iso8601(field, value)
    return if value.blank?

    Time.iso8601(value.to_s)
  rescue ArgumentError
    errors.add(field, "#{field} must be a valid ISO-8601 timestamp")
  end
end
