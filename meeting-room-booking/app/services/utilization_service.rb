class UtilizationService
  class << self
    def generate(from, to)
      from_time = Time.iso8601(from.to_s)
      to_time = Time.iso8601(to.to_s)
      total_business_hours = BookingRules.business_hours_between(from_time, to_time)

      Room.includes(:confirmed_bookings).order(:id).map do |room|
        booked_hours = room.confirmed_bookings.sum do |booking|
          BookingRules.booked_hours_in_range(booking, from_time, to_time)
        end

        utilization_percent =
          if total_business_hours.zero?
            0.0
          else
            (booked_hours / total_business_hours).round(4)
          end

        {
          roomId: room.id.to_s,
          roomName: room.name,
          totalBookingHours: booked_hours.round(2),
          utilizationPercent: utilization_percent
        }
      end
    end
  end
end
