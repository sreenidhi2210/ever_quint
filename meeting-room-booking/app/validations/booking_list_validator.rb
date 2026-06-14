class BookingListValidator < ApiValidation
  attr_accessor :room_id, :from, :to, :limit, :offset

  validate :from_must_be_iso8601
  validate :to_must_be_iso8601
  validate :limit_must_be_positive_integer
  validate :offset_must_be_non_negative_integer

  private

  def from_must_be_iso8601
    validate_iso8601(:from, from)
  end

  def to_must_be_iso8601
    validate_iso8601(:to, to)
  end

  def limit_must_be_positive_integer
    validate_positive_integer(:limit, limit)
  end

  def offset_must_be_non_negative_integer
    return if offset.blank?

    unless offset.to_s.match?(/\A\d+\z/)
      errors.add(:offset, "offset must be a non-negative integer")
    end
  end

  def validate_iso8601(field, value)
    return if value.blank?

    Time.iso8601(value.to_s)
  rescue ArgumentError
    errors.add(field, "#{field} must be a valid ISO-8601 timestamp")
  end

  def validate_positive_integer(field, value)
    return if value.blank?

    unless value.to_s.match?(/\A[1-9]\d*\z/)
      errors.add(field, "#{field} must be a positive integer")
    end
  end
end
