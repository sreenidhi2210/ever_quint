class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :rooms, :name, unique: true
    add_index :bookings, [:room_id, :status, :start_time, :end_time],
              name: "index_bookings_on_room_status_and_times"
  end
end
