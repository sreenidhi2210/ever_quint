class ValidationError < ApplicationError
  def initialize(message)
    super(message, status: :bad_request)
  end
end
