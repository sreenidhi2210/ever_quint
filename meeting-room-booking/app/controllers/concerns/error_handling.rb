module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ApplicationError, with: :render_application_error
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  end

  private

  def render_validation_errors(validator)
    return if validator.valid?

    render_error(
      error: "ValidationError",
      message: validator.first_error_message,
      status: :bad_request
    )
  end

  def render_model_errors(record)
    message = record.errors.full_messages.first

    render_error(
      error: "ValidationError",
      message: message,
      status: :bad_request
    )
  end

  def render_application_error(exception)
    error_type =
      case exception
      when ValidationError then "ValidationError"
      when NotFoundError then "NotFoundError"
      when ConflictError then "ConflictError"
      else "ApplicationError"
      end

    render_error(
      error: error_type,
      message: exception.message,
      status: exception.status
    )
  end

  def render_not_found(_exception)
    render_error(
      error: "NotFoundError",
      message: "Resource not found",
      status: :not_found
    )
  end

  def render_record_invalid(exception)
    render_model_errors(exception.record)
  end

  def render_error(error:, message:, status:)
    render json: { error: error, message: message }, status: status
  end
end
