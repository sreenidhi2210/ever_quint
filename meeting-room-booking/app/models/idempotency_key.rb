class IdempotencyKey < ApplicationRecord
  PROCESSING = "processing"
  COMPLETED = "completed"

  belongs_to :booking, optional: true

  validates :key, presence: true
  validates :organizer_email, presence: true
  validates :status, presence: true
  validates :request_hash, presence: true

  validates :key,
            uniqueness: {
              scope: :organizer_email,
              case_sensitive: true
            }

  def completed?
    status == COMPLETED
  end

  def processing?
    status == PROCESSING
  end
end
