class BookingRules
  MIN_DURATION = 15.minutes
  MAX_DURATION = 4.hours
  BUSINESS_START_HOUR = 8
  BUSINESS_END_HOUR = 20
  BUSINESS_DAYS = (1..5).to_a

  class << self
    def validate!(start_time:, end_time:)
      start_time = parse_time(start_time)
      end_time = parse_time(end_time)

      validate_time_order!(start_time, end_time)
      validate_duration!(start_time, end_time)
      validate_business_hours!(start_time, end_time)

      { start_time: start_time, end_time: end_time }
    end

    def overlapping?(room_id:, start_time:, end_time:, exclude_id: nil)
      scope = Booking.confirmed.where(room_id: room_id)
      scope = scope.where.not(id: exclude_id) if exclude_id

      scope.where("start_time < ? AND end_time > ?", end_time, start_time).exists?
    end

    def cancellation_allowed?(booking, now: Time.current)
      now <= booking.start_time - 1.hour
    end

    def business_hours_between(from_time, to_time)
      total_seconds = 0.0
      current = from_time.in_time_zone.beginning_of_day
      finish = to_time.in_time_zone

      while current < finish
        if business_day?(current)
          day_start = business_day_start(current)
          day_end = business_day_end(current)
          overlap_start = [day_start, from_time.in_time_zone].max
          overlap_end = [day_end, finish].min

          if overlap_start < overlap_end
            total_seconds += overlap_end - overlap_start
          end
        end

        current += 1.day
      end

      total_seconds / 1.hour
    end

    def booked_hours_in_range(booking, from_time, to_time)
      overlap_start = [booking.start_time.in_time_zone, from_time.in_time_zone].max
      overlap_end = [booking.end_time.in_time_zone, to_time.in_time_zone].min
      return 0.0 if overlap_start >= overlap_end

      business_hours_between(overlap_start, overlap_end)
    end

    private

    def parse_time(value)
      value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) ? value : Time.iso8601(value.to_s)
    end

    def validate_time_order!(start_time, end_time)
      if start_time >= end_time
        raise ValidationError, "startTime must be before endTime"
      end
    end

    def validate_duration!(start_time, end_time)
      duration = end_time - start_time

      if duration < MIN_DURATION
        raise ValidationError, "Booking duration must be at least 15 minutes"
      end

      if duration > MAX_DURATION
        raise ValidationError, "Booking duration must not exceed 4 hours"
      end
    end

    def validate_business_hours!(start_time, end_time)
      unless within_business_hours?(start_time) && within_business_hours?(end_time)
        raise ValidationError,
              "Bookings are only allowed Monday through Friday between 08:00 and 20:00"
      end

      if crosses_non_business_period?(start_time, end_time)
        raise ValidationError,
              "Bookings are only allowed Monday through Friday between 08:00 and 20:00"
      end
    end

    def within_business_hours?(time)
      local = time.in_time_zone
      return false unless business_day?(local)

      minutes = local.hour * 60 + local.min
      start_minutes = BUSINESS_START_HOUR * 60
      end_minutes = BUSINESS_END_HOUR * 60

      minutes >= start_minutes && minutes <= end_minutes
    end

    def crosses_non_business_period?(start_time, end_time)
      local_start = start_time.in_time_zone
      local_end = end_time.in_time_zone
      current = local_start

      while current < local_end
        unless within_business_hours?(current)
          return true
        end

        current += 15.minutes
      end

      false
    end

    def business_day?(time)
      BUSINESS_DAYS.include?(time.wday)
    end

    def business_day_start(time)
      time.in_time_zone.change(hour: BUSINESS_START_HOUR, min: 0, sec: 0)
    end

    def business_day_end(time)
      time.in_time_zone.change(hour: BUSINESS_END_HOUR, min: 0, sec: 0)
    end
  end
end
