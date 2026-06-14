class ApiValidation
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :params

  def initialize(params = {})
    @params = params.with_indifferent_access
    super(@params)
  end

  def first_error_message
    errors.full_messages.first
  end
end
