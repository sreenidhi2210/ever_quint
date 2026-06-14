class RoomListValidator < ApiValidation
  attr_accessor :min_capacity, :amenity

  validate :min_capacity_must_be_integer

  private

  def min_capacity_must_be_integer
    return if min_capacity.blank?

    unless min_capacity.to_s.match?(/\A-?\d+\z/)
      errors.add(:min_capacity, "minCapacity must be an integer")
    end
  end
end
