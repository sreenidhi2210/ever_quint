class ConflictError < ApplicationError
  def initialize(message)
    super(message, status: :conflict)
  end
end
