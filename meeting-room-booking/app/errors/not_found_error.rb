class NotFoundError < ApplicationError
  def initialize(message = "Resource not found")
    super(message, status: :not_found)
  end
end
