# frozen_string_literal: true

require "rails_helper"

RSpec.describe UtilizationService do
  let!(:room) { Room.create!(name: "Util Room", capacity: 10, floor: 1) }

  # Tuesday 2026-06-17, one full business day in range
  let(:from) { "2026-06-17T00:00:00Z" }
  let(:to) { "2026-06-18T00:00:00Z" }

  def report_for(room_id)
    described_class
      .generate(from, to)
      .find { |entry| entry[:roomId] == room_id.to_s }
  end

  it "returns 0 utilization when there are no bookings" do
    entry = report_for(room.id)

    expect(entry[:totalBookingHours]).to eq(0.0)
    expect(entry[:utilizationPercent]).to eq(0.0)
  end

  it "counts a booking fully inside the range" do
    Booking.create!(
      room: room,
      title: "Full booking",
      organizer_email: "a@example.com",
      start_time: "2026-06-17T09:00:00Z",
      end_time: "2026-06-17T11:00:00Z",
      status: "confirmed"
    )

    entry = report_for(room.id)

    expect(entry[:totalBookingHours]).to eq(2.0)
    expect(entry[:utilizationPercent]).to eq((2.0 / 12.0).round(4))
  end

  it "clips a booking that starts before the range" do
    Booking.create!(
      room: room,
      title: "Starts early",
      organizer_email: "b@example.com",
      start_time: "2026-06-16T17:00:00Z", # Monday 17:00
      end_time: "2026-06-17T10:00:00Z",   # Tuesday 10:00
      status: "confirmed"
    )

    entry = report_for(room.id)

    # Only Tuesday 08:00-10:00 counts = 2 hours
    expect(entry[:totalBookingHours]).to eq(2.0)
  end

  it "clips a booking that ends after the range" do
    Booking.create!(
      room: room,
      title: "Ends late",
      organizer_email: "c@example.com",
      start_time: "2026-06-17T18:00:00Z",
      end_time: "2026-06-18T10:00:00Z",
      status: "confirmed"
    )

    entry = report_for(room.id)

    # Only Tuesday 18:00-20:00 counts = 2 hours
    expect(entry[:totalBookingHours]).to eq(2.0)
  end

  it "ignores cancelled bookings" do
    Booking.create!(
      room: room,
      title: "Cancelled",
      organizer_email: "d@example.com",
      start_time: "2026-06-17T09:00:00Z",
      end_time: "2026-06-17T11:00:00Z",
      status: "cancelled"
    )

    entry = report_for(room.id)

    expect(entry[:totalBookingHours]).to eq(0.0)
    expect(entry[:utilizationPercent]).to eq(0.0)
  end
end
