module ParamNormalization
  extend ActiveSupport::Concern

  private

  def normalize_params!
    params.deep_transform_keys! { |key| key.to_s.underscore }
  end
end
