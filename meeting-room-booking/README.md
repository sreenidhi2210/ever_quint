# Meeting Room Booking Service

Rails 7 API for managing meeting rooms, bookings, cancellations, idempotent booking creation, and utilization reports.

See [DESIGN.md](DESIGN.md) for architecture, overlap enforcement, idempotency, and utilization formulas.

## Requirements

- Ruby 3.4.2
- MySQL 5.7+

## Setup

```bash
cd meeting_room_booking
bundle install
bin/rails db:create db:migrate
bin/rails server
```

The API listens on `http://localhost:3000`.

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/rooms` | Create a room |
| `GET` | `/rooms` | List rooms (`minCapacity`, `amenity` filters) |
| `POST` | `/bookings` | Create a booking (`Idempotency-Key` header optional) |
| `GET` | `/bookings` | List bookings (pagination + filters) |
| `POST` | `/bookings/:id/cancel` | Cancel a booking |
| `GET` | `/reports/room-utilization` | Room utilization report (`from`, `to` required) |

## Error Format

```json
{
  "error": "ValidationError",
  "message": "startTime must be before endTime"
}
```

## Example Requests

**Create room**

```bash
curl -X POST http://localhost:3000/rooms \
  -H "Content-Type: application/json" \
  -d '{"name":"Boardroom","capacity":12,"floor":3,"amenities":["projector","whiteboard"]}'
```

**Create booking**

```bash
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: booking-abc-123" \
  -d '{
    "roomId": 1,
    "title": "Sprint Planning",
    "organizerEmail": "lead@example.com",
    "startTime": "2026-06-17T09:00:00Z",
    "endTime": "2026-06-17T10:00:00Z"
  }'
```

**Utilization report**

```bash
curl "http://localhost:3000/reports/room-utilization?from=2026-06-01T00:00:00Z&to=2026-06-30T23:59:59Z"
```

## Test Suite

The project uses **RSpec**. All tests live under `spec/`.

### Prerequisites

Make sure dependencies and the test database are ready:

```bash
cd meeting_room_booking
bundle install
bin/rails db:test:prepare
```

### Run all tests

```bash
bundle exec rspec
```

Expected output ends with:

```
22 examples, 0 failures
```

### Run a single file

```bash
bundle exec rspec spec/services/booking_rules_spec.rb
bundle exec rspec spec/requests/bookings_spec.rb
bundle exec rspec spec/services/cancellation_service_spec.rb
bundle exec rspec spec/services/utilization_service_spec.rb
```

### Run one example by line number

```bash
bundle exec rspec spec/requests/bookings_spec.rb:19
```

### What is covered

| Spec file | Type | Scenarios |
|---|---|---|
| `spec/services/booking_rules_spec.rb` | Unit | Duration (15 min – 4 hr), Mon–Fri 08:00–20:00, overlap detection, cancelled bookings don't block, cancellation window |
| `spec/requests/bookings_spec.rb` | Integration | `POST /bookings` happy path (201), overlap conflict (409), idempotency (same key → same booking, no duplicate rows) |
| `spec/services/cancellation_service_spec.rb` | Unit | Cancel allowed ≥ 1 hr before start, blocked within 1 hr, already-cancelled is a no-op |
| `spec/services/utilization_service_spec.rb` | Unit | Zero utilization, full booking, partial overlap (starts before / ends after range), cancelled bookings excluded |

### Test structure

```
spec/
├── rails_helper.rb          # Rails + DB setup, freezes time to 2026-06-16
├── spec_helper.rb
├── services/
│   ├── booking_rules_spec.rb
│   ├── cancellation_service_spec.rb
│   └── utilization_service_spec.rb
└── requests/
    └── bookings_spec.rb     # full HTTP integration tests
```

