class UpdateIdempotencyKeys < ActiveRecord::Migration[7.0]
  def change
    change_column_null :idempotency_keys, :booking_id, true

    add_index :idempotency_keys,
              [:key, :organizer_email],
              unique: true,
              name: "index_idempotency_keys_on_key_and_organizer_email"
  end
end
