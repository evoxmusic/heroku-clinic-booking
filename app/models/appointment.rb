class Appointment < ApplicationRecord
  belongs_to :practitioner
  belongs_to :patient

  STATUSES = %w[booked confirmed cancelled done].freeze
  validates :starts_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :upcoming, -> { where("starts_at > ?", Time.current) }
  scope :due_for_reminder, lambda {
    window = CLINIC[:reminder_hours_before].hours
    where(reminded_at: nil, status: %w[booked confirmed])
      .where(starts_at: Time.current..(Time.current + window))
  }
end
