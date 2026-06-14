class RoomCreateValidator < ApiValidation
  attr_accessor :name, :capacity, :floor, :amenities

  validates :name, presence: { message: "name is required" }
  validates :capacity,
            presence: { message: "capacity is required" },
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              message: "capacity must be a positive integer"
            }
  validates :floor,
            presence: { message: "floor is required" },
            numericality: {
              only_integer: true,
              message: "floor must be an integer"
            }
  validate :amenities_must_be_array

  private

  def amenities_must_be_array
    return if amenities.nil?

    unless amenities.is_a?(Array)
      errors.add(:amenities, "amenities must be an array")
    end
  end
end
