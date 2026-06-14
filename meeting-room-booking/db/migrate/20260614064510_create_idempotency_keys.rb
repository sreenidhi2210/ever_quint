class CreateIdempotencyKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :idempotency_keys do |t|
      t.string :key
      t.string :organizer_email
      t.references :booking, null: false, foreign_key: true
      t.string :request_hash
      t.string :status

      t.timestamps
    end
  end
end
