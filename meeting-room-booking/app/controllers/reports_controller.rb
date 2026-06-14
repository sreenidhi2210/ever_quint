class ReportsController < ApplicationController
  include ReportsValidationMethods

  before_action :validate_utilization_params, only: [:room_utilization]

  def room_utilization
    result = UtilizationService.generate(params[:from], params[:to])

    render json: result, status: :ok
  end
end
