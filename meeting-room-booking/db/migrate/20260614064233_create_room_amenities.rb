class CreateRoomAmenities < ActiveRecord::Migration[7.0]
  def change
    create_table :room_amenities do |t|
      t.references :room, null: false, foreign_key: true
      t.string :amenity

      t.timestamps
    end
  end
end
