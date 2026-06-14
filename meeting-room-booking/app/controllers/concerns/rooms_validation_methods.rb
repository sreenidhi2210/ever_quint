module RoomsValidationMethods
  extend ActiveSupport::Concern

  private

  def validate_create_params
    render_validation_errors(create_validator) unless create_validator.valid?
  end

  def validate_list_params
    render_validation_errors(list_validator) unless list_validator.valid?
  end

  def create_validator
    @_create_validator ||= RoomCreateValidator.new(room_params.to_h)
  end

  def list_validator
    @_list_validator ||= RoomListValidator.new(
      min_capacity: params[:min_capacity],
      amenity: params[:amenity]
    )
  end
end
