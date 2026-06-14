class ApplicationController < ActionController::API
  include ErrorHandling
  include ParamNormalization

  wrap_parameters false

  before_action :normalize_params!
end
