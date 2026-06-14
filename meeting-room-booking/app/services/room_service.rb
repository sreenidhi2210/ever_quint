class RoomService
  class << self
    def create(params)
      amenities = Array(params[:amenities]).compact
      room = Room.new(
        name: params[:name],
        capacity: params[:capacity],
        floor: params[:floor]
      )

      return room unless room.save

      amenities.each do |amenity|
        room.room_amenities.create!(amenity: amenity)
      end

      room.reload
    end

    def list(params)
      rooms = Room.includes(:room_amenities)

      if params[:min_capacity].present?
        rooms = rooms.where("capacity >= ?", params[:min_capacity].to_i)
      end

      if params[:amenity].present?
        rooms = rooms.joins(:room_amenities)
                     .where(room_amenities: { amenity: params[:amenity] })
      end

      rooms.distinct.order(:id)
    end
  end
end
