module ApiSerializer
  module_function

  def room(room)
    {
      id: room.id,
      name: room.name,
      capacity: room.capacity,
      floor: room.floor,
      amenities: room.room_amenities.map(&:amenity)
    }
  end

  def rooms(rooms)
    rooms.map { |room| ApiSerializer.room(room) }
  end

  def booking(booking)
    {
      id: booking.id,
      roomId: booking.room_id,
      title: booking.title,
      organizerEmail: booking.organizer_email,
      startTime: booking.start_time.iso8601,
      endTime: booking.end_time.iso8601,
      status: booking.status
    }
  end

  def bookings(bookings)
    bookings.map { |booking| ApiSerializer.booking(booking) }
  end
end
