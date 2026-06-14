module ReportsValidationMethods
  extend ActiveSupport::Concern

  private

  def validate_utilization_params
    render_validation_errors(utilization_validator) unless utilization_validator.valid?
  end

  def utilization_validator
    @_utilization_validator ||= ReportUtilizationValidator.new(
      from: params[:from],
      to: params[:to]
    )
  end
end
