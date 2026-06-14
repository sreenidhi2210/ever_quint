require "digest"

class BookingService
  IDEMPOTENCY_WAIT_SECONDS = 5
  IDEMPOTENCY_POLL_INTERVAL = 0.1

  class << self
    def create(params, idempotency_key = nil)
      if idempotency_key.present?
        create_with_idempotency(params, idempotency_key)
      else
        create_booking!(params)
      end
    end

    def list(params)
      bookings = Booking.order(:start_time)

      if params[:room_id].present?
        bookings = bookings.where(room_id: params[:room_id])
      end

      if params[:from].present?
        from_time = Time.iso8601(params[:from].to_s)
        bookings = bookings.where("end_time > ?", from_time)
      end

      if params[:to].present?
        to_time = Time.iso8601(params[:to].to_s)
        bookings = bookings.where("start_time < ?", to_time)
      end

      total = bookings.count
      limit = (params[:limit] || 20).to_i
      offset = (params[:offset] || 0).to_i

      {
        items: bookings.limit(limit).offset(offset),
        total: total,
        limit: limit,
        offset: offset
      }
    end

    private

    def create_with_idempotency(params, idempotency_key)
      organizer_email = params[:organizer_email]
      request_hash = request_fingerprint(params)

      existing = IdempotencyKey.find_by(
        key: idempotency_key,
        organizer_email: organizer_email
      )

      if existing
        return handle_existing_idempotency(existing, request_hash)
      end

      begin
        booking = nil

        Booking.transaction do
          idempotency_record = IdempotencyKey.create!(
            key: idempotency_key,
            organizer_email: organizer_email,
            request_hash: request_hash,
            status: IdempotencyKey::PROCESSING
          )

          booking = create_booking!(params)

          idempotency_record.update!(
            booking: booking,
            status: IdempotencyKey::COMPLETED
          )
        end

        booking
      rescue ActiveRecord::RecordNotUnique
        existing = IdempotencyKey.find_by!(
          key: idempotency_key,
          organizer_email: organizer_email
        )
        handle_existing_idempotency(existing, request_hash)
      end
    end

    def handle_existing_idempotency(record, request_hash)
      # If Idempotency-Key is same but the request body is different
      if record.request_hash != request_hash
        raise ValidationError,
              "Idempotency-Key has already been used with a different request body"
      end

      if record.completed? && record.booking
        return record.booking
      end

      wait_for_completion(record)
    end

    def wait_for_completion(record)
      deadline = Time.current + IDEMPOTENCY_WAIT_SECONDS

      while Time.current < deadline
        record.reload

        if record.completed? && record.booking
          return record.booking
        end

        sleep(IDEMPOTENCY_POLL_INTERVAL)
      end

      raise ConflictError, "A booking with this Idempotency-Key is still being processed"
    end

    def create_booking!(params)
      room = Room.find_by(id: params[:room_id])
      raise NotFoundError, "Room not found" unless room

      times = BookingRules.validate!(
        start_time: params[:start_time],
        end_time: params[:end_time]
      )

      start_time = times[:start_time]
      end_time = times[:end_time]

      if BookingRules.overlapping?(
        room_id: room.id,
        start_time: start_time,
        end_time: end_time
      )
        raise ConflictError, "Booking overlaps with an existing confirmed booking"
      end

      Booking.create!(
        room: room,
        title: params[:title],
        organizer_email: params[:organizer_email],
        start_time: start_time,
        end_time: end_time,
        status: "confirmed"
      )
    end

    def request_fingerprint(params)
      canonical = {
        room_id: params[:room_id].to_s,
        title: params[:title].to_s,
        organizer_email: params[:organizer_email].to_s,
        start_time: params[:start_time].to_s,
        end_time: params[:end_time].to_s
      }

      Digest::SHA256.hexdigest(canonical.to_json)
    end
  end
end
