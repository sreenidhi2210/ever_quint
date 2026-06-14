class Booking < ApplicationRecord
  belongs_to :room

  enum status: {
    confirmed: "confirmed",
    cancelled: "cancelled"
  }

  scope :confirmed, -> { where(status: "confirmed") }
end
