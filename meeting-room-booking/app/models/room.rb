class Room < ApplicationRecord
  has_many :room_amenities, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :confirmed_bookings, -> { confirmed }, class_name: "Booking"

  validates :name,
            presence: true,
            uniqueness: {
              case_sensitive: false,
              message: "name must be unique"
            }

  validates :capacity,
            numericality: { greater_than: 0 }
end