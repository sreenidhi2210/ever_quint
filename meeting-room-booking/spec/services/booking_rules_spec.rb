# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingRules do
  let(:room) { Room.create!(name: "Test Room", capacity: 10, floor: 1) }

  describe ".validate!" do
    it "accepts a valid weekday booking" do
      result = described_class.validate!(
        start_time: "2026-06-17T09:00:00Z",
        end_time: "2026-06-17T10:00:00Z"
      )

      expect(result[:start_time]).to be_present
      expect(result[:end_time]).to be_present
    end

    it "rejects when startTime is not before endTime" do
      expect {
        described_class.validate!(
          start_time: "2026-06-17T10:00:00Z",
          end_time: "2026-06-17T09:00:00Z"
        )
      }.to raise_error(ValidationError, "startTime must be before endTime")
    end

    it "rejects bookings shorter than 15 minutes" do
      expect {
        described_class.validate!(
          start_time: "2026-06-17T09:00:00Z",
          end_time: "2026-06-17T09:10:00Z"
        )
      }.to raise_error(ValidationError, "Booking duration must be at least 15 minutes")
    end

    it "rejects bookings longer than 4 hours" do
      expect {
        described_class.validate!(
          start_time: "2026-06-17T09:00:00Z",
          end_time: "2026-06-17T14:00:00Z"
        )
      }.to raise_error(ValidationError, "Booking duration must not exceed 4 hours")
    end

    it "rejects weekend bookings" do
      expect {
        described_class.validate!(
          start_time: "2026-06-14T09:00:00Z", # Sunday
          end_time: "2026-06-14T10:00:00Z"
        )
      }.to raise_error(ValidationError, /Monday through Friday/)
    end

    it "rejects bookings outside 08:00-20:00" do
      expect {
        described_class.validate!(
          start_time: "2026-06-17T07:00:00Z",
          end_time: "2026-06-17T08:00:00Z"
        )
      }.to raise_error(ValidationError, /Monday through Friday/)
    end
  end

  describe ".overlapping?" do
    before do
      Booking.create!(
        room: room,
        title: "Existing",
        organizer_email: "existing@example.com",
        start_time: "2026-06-17T09:00:00Z",
        end_time: "2026-06-17T10:00:00Z",
        status: "confirmed"
      )
    end

    it "returns true when a confirmed booking overlaps" do
      overlap = described_class.overlapping?(
        room_id: room.id,
        start_time: "2026-06-17T09:30:00Z",
        end_time: "2026-06-17T10:30:00Z"
      )

      expect(overlap).to be true
    end

    it "returns false when there is no overlap" do
      overlap = described_class.overlapping?(
        room_id: room.id,
        start_time: "2026-06-17T10:00:00Z",
        end_time: "2026-06-17T11:00:00Z"
      )

      expect(overlap).to be false
    end

    it "ignores cancelled bookings" do
      Booking.update_all(status: "cancelled")

      overlap = described_class.overlapping?(
        room_id: room.id,
        start_time: "2026-06-17T09:30:00Z",
        end_time: "2026-06-17T10:30:00Z"
      )

      expect(overlap).to be false
    end
  end

  describe ".cancellation_allowed?" do
    let(:booking) do
      Booking.new(start_time: Time.zone.parse("2026-06-17T12:00:00Z"))
    end

    it "allows cancellation more than 1 hour before start" do
      allowed = described_class.cancellation_allowed?(
        booking,
        now: Time.zone.parse("2026-06-17T10:00:00Z")
      )

      expect(allowed).to be true
    end

    it "denies cancellation less than 1 hour before start" do
      allowed = described_class.cancellation_allowed?(
        booking,
        now: Time.zone.parse("2026-06-17T11:30:00Z")
      )

      expect(allowed).to be false
    end
  end
end
