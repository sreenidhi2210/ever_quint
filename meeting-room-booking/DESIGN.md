# Meeting Room Booking Service — Design

## Data Model

```
rooms
  id, name (unique, case-insensitive), capacity, floor, timestamps

room_amenities
  id, room_id (FK), amenity, timestamps

bookings
  id, room_id (FK), title, organizer_email, start_time, end_time,
  status (confirmed | cancelled), timestamps

idempotency_keys
  id, key, organizer_email, booking_id (FK, nullable while processing),
  request_hash, status (processing | completed), timestamps
  unique index on (key, organizer_email)
```

**Relationships**

- A room has many amenities and many bookings.
- A booking belongs to a room.
- An idempotency key belongs to a booking once processing completes.

**Idempotency key scope**

Keys are unique per `organizer_email`. Two organizers may reuse the same key string without conflict. The same organizer reusing a key with an identical request body returns the original booking; reusing a key with a different body returns `400`.

## Layering

| Layer | Responsibility |
|---|---|
| Controllers | HTTP, param normalization, `before_action` validation, response serialization |
| Validations (`app/validations/`) | Request-shape checks (presence, types, ISO-8601, email format) |
| Services | Business rules, transactions, idempotency orchestration |
| Models | Persistence constraints (uniqueness, associations) |
| `BookingRules` | Pure booking policy logic (duration, hours, overlap helpers) |

Controllers follow the same pattern as `PortalsController`: a validation concern exposes a `validator` and a `before_action` calls `render_validation_errors unless validator.valid?` before the action runs.

## Overlap Prevention

Overlap is checked in `BookingService` before insert:

```sql
SELECT 1 FROM bookings
WHERE room_id = ? AND status = 'confirmed'
  AND start_time < :end_time AND end_time > :start_time
```

Only **confirmed** bookings block new bookings. **Cancelled** bookings are excluded, so a cancelled slot can be rebooked.

On conflict the API returns `409` with:

```json
{ "error": "ConflictError", "message": "Booking overlaps with an existing confirmed booking" }
```

## Error Handling Strategy

All API errors use a consistent envelope:

```json
{ "error": "<ErrorType>", "message": "<human-readable message>" }
```

| HTTP Status | Error Type | When |
|---|---|---|
| 400 | `ValidationError` | Invalid/missing params, business-rule violations, idempotency body mismatch |
| 404 | `NotFoundError` | Unknown room or booking |
| 409 | `ConflictError` | Overlapping booking, idempotency key still processing |

**Where errors originate**

1. **Controller validators** — shape/format validation via `before_action` (returns 400, halts request).
2. **Model validations** — e.g. duplicate room name on create (returns 400 via `render_model_errors`).
3. **Services** — raise `ValidationError`, `NotFoundError`, or `ConflictError`; rescued in `ErrorHandling` concern.

## Idempotency

`POST /bookings` accepts an optional `Idempotency-Key` header.

**Flow**

1. Compute a SHA-256 fingerprint of the normalized request body.
2. Look up `(key, organizer_email)` in `idempotency_keys`.
3. If found and `completed` → return the stored booking (200 semantics, still `201` on first create; subsequent identical calls also return the booking).
4. If found and `processing` → poll up to 5 seconds; return booking when complete, else `409`.
5. If not found → insert row with `status: processing` inside a DB transaction, create the booking, then mark `completed`.

**Persistence**

Data lives in the `idempotency_keys` table so it survives process restarts.

**Concurrency**

A unique DB index on `(key, organizer_email)` ensures only one in-flight record per key/organizer. Concurrent requests that race on insert rescue `ActiveRecord::RecordNotUnique` and follow the existing-record path (poll or return completed booking). This avoids duplicate bookings without an in-memory lock.

## Booking Business Rules (`BookingRules`)

- `startTime < endTime`
- Duration between **15 minutes** and **4 hours**
- Entire booking must fall within **Mon–Fri, 08:00–20:00** (application timezone, default UTC)
- Cancellation allowed only **≥ 1 hour** before `startTime`; already-cancelled bookings are a no-op

## Utilization Calculation

`GET /reports/room-utilization?from=&to=`

For each room:

```
totalBookingHours = Σ clipped confirmed-booking hours within [from, to]
totalBusinessHours = business hours (Mon–Fri 08:00–20:00) in [from, to]
utilizationPercent = totalBookingHours / totalBusinessHours   (0 if denominator is 0)
```

**Clipping**

A booking that starts before `from` or ends after `to` contributes only the overlapping portion. Only **confirmed** bookings count.

**Assumptions**

- Business hours = 12 h/day on weekdays (08:00–20:00 inclusive at boundaries).
- Timezone = `Rails.application.config.time_zone` (UTC). All rooms share this timezone.

## API Conventions

- Request/response bodies use **camelCase** (`roomId`, `startTime`, …).
- Controllers normalize incoming params to **snake_case** via `ParamNormalization`.
- Responses are serialized through `ApiSerializer`.
