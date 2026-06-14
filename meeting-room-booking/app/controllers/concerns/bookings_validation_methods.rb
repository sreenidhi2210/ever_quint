module BookingsValidationMethods
  extend ActiveSupport::Concern

  private

  def validate_create_params
    render_validation_errors(create_validator) unless create_validator.valid?
  end

  def validate_list_params
    render_validation_errors(list_validator) unless list_validator.valid?
  end

  def create_validator
    @_create_validator ||= BookingCreateValidator.new(booking_params.to_h)
  end

  def list_validator
    @_list_validator ||= BookingListValidator.new(
      room_id: params[:room_id],
      from: params[:from],
      to: params[:to],
      limit: params[:limit],
      offset: params[:offset]
    )
  end
end
