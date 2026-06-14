# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bookings API", type: :request do
  let!(:room) { Room.create!(name: "Boardroom", capacity: 12, floor: 2) }

  let(:valid_payload) do
    {
      roomId: room.id,
      title: "Sprint Planning",
      organizerEmail: "lead@example.com",
      startTime: "2026-06-17T09:00:00Z",
      endTime: "2026-06-17T10:00:00Z"
    }
  end

  describe "POST /bookings" do
    it "creates a confirmed booking (happy path)" do
      post "/bookings", params: valid_payload, as: :json

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("confirmed")
      expect(body["id"]).to be_present
      expect(body["roomId"]).to eq(room.id)
      expect(Booking.count).to eq(1)
    end

    it "returns 409 when booking overlaps an existing one" do
      Booking.create!(
        room: room,
        title: "Morning Sync",
        organizer_email: "other@example.com",
        start_time: "2026-06-17T09:00:00Z",
        end_time: "2026-06-17T10:00:00Z",
        status: "confirmed"
      )

      overlapping_payload = valid_payload.merge(
        startTime: "2026-06-17T09:30:00Z",
        endTime: "2026-06-17T10:30:00Z"
      )

      post "/bookings", params: overlapping_payload, as: :json

      expect(response).to have_http_status(:conflict)

      body = JSON.parse(response.body)
      expect(body["error"]).to eq("ConflictError")
      expect(body["message"]).to include("overlap")
      expect(Booking.count).to eq(1)
    end

    it "returns the same booking for duplicate idempotency key (no duplicates)" do
      headers = { "Idempotency-Key" => "booking-abc-123" }

      post "/bookings", params: valid_payload, headers: headers, as: :json
      first_body = JSON.parse(response.body)
      expect(response).to have_http_status(:created)

      post "/bookings", params: valid_payload, headers: headers, as: :json
      second_body = JSON.parse(response.body)
      expect(response).to have_http_status(:created)

      expect(second_body["id"]).to eq(first_body["id"])
      expect(Booking.count).to eq(1)
      expect(IdempotencyKey.count).to eq(1)
    end
  end
end
