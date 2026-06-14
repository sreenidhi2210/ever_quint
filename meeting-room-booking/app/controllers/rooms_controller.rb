class RoomsController < ApplicationController
  include RoomsValidationMethods

  before_action :validate_create_params, only: [:create]
  before_action :validate_list_params, only: [:index]

  def create
    room = RoomService.create(room_params)

    if room.persisted?
      render json: ApiSerializer.room(room), status: :created
    else
      render_model_errors(room)
    end
  end

  def index
    rooms = RoomService.list(params)

    render json: ApiSerializer.rooms(rooms), status: :ok
  end

  private

  def room_params
    params.permit(:name, :capacity, :floor, amenities: [])
  end
end
