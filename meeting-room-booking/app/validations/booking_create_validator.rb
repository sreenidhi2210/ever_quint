class BookingCreateValidator < ApiValidation
  attr_accessor :room_id, :title, :organizer_email, :start_time, :end_time

  validates :room_id, presence: { message: "roomId is required" }
  validates :title, presence: { message: "title is required" }
  validates :organizer_email,
            presence: { message: "organizerEmail is required" },
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: "organizerEmail must be a valid email address"
            }
  validates :start_time, presence: { message: "startTime is required" }
  validates :end_time, presence: { message: "endTime is required" }
  validate :start_time_must_be_iso8601
  validate :end_time_must_be_iso8601

  private

  def start_time_must_be_iso8601
    validate_iso8601(:start_time, start_time)
  end

  def end_time_must_be_iso8601
    validate_iso8601(:end_time, end_time)
  end

  def validate_iso8601(field, value)
    return if value.blank?

    Time.iso8601(value.to_s)
  rescue ArgumentError
    errors.add(field, "#{field.to_s.camelize(:lower)} must be a valid ISO-8601 timestamp")
  end
end
