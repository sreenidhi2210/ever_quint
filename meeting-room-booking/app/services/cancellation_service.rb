class CancellationService
  class << self
    def cancel(booking_id)
      booking = Booking.find_by(id: booking_id)
      raise NotFoundError, "Booking not found" unless booking

      return booking if booking.cancelled?

      unless BookingRules.cancellation_allowed?(booking)
        raise ValidationError,
              "Booking can only be cancelled at least 1 hour before start time"
      end

      booking.update!(status: "cancelled")
      booking
    end
  end
end
