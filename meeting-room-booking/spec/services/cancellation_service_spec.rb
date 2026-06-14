# frozen_string_literal: true

require "rails_helper"

RSpec.describe CancellationService do
  let(:room) { Room.create!(name: "Cancel Room", capacity: 8, floor: 1) }

  let!(:booking) do
    Booking.create!(
      room: room,
      title: "Review",
      organizer_email: "user@example.com",
      start_time: "2026-06-17T14:00:00Z",
      end_time: "2026-06-17T15:00:00Z",
      status: "confirmed"
    )
  end

  describe ".cancel" do
    it "cancels a booking more than 1 hour before start" do
      travel_to Time.zone.parse("2026-06-17T12:00:00Z")

      result = described_class.cancel(booking.id)

      expect(result.status).to eq("cancelled")
    end

    it "raises when cancelling less than 1 hour before start" do
      travel_to Time.zone.parse("2026-06-17T13:30:00Z")

      expect {
        described_class.cancel(booking.id)
      }.to raise_error(ValidationError, /at least 1 hour before/)
    end

    it "returns the booking unchanged when already cancelled" do
      booking.update!(status: "cancelled")

      result = described_class.cancel(booking.id)

      expect(result.status).to eq("cancelled")
      expect(result.id).to eq(booking.id)
    end
  end
end
