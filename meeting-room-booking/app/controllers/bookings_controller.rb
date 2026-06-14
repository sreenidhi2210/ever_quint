class BookingsController < ApplicationController
  include BookingsValidationMethods

  before_action :validate_create_params, only: [:create]
  before_action :validate_list_params, only: [:index]

  def create
    booking = BookingService.create(
      booking_params.to_h,
      request.headers["Idempotency-Key"]
    )

    render json: ApiSerializer.booking(booking), status: :created
  end

  def index
    result = BookingService.list(params)

    render json: {
      items: ApiSerializer.bookings(result[:items]),
      total: result[:total],
      limit: result[:limit],
      offset: result[:offset]
    }, status: :ok
  end

  def cancel
    booking = CancellationService.cancel(params[:id])

    render json: ApiSerializer.booking(booking), status: :ok
  end

  private

  def booking_params
    params.permit(:room_id, :title, :organizer_email, :start_time, :end_time)
  end
end
