class Practitioner < ApplicationRecord
  has_many :appointments, dependent: :destroy

  SPECIALTIES = %w[
    general_practitioner dentist dermatologist cardiologist pediatrician
    gynecologist ophthalmologist physiotherapist psychiatrist osteopath
  ].freeze

  # Consultation hours: 09:00 to 17:30, every 30 minutes, Monday to Friday.
  SLOT_TIMES = (9..17).flat_map { |h| [[h, 0], [h, 30]] }.freeze
  BOOKING_DAYS = 5

  validates :first_name, :last_name, :specialty, :city, presence: true

  scope :in_city, ->(city) { where(city: city) if city.present? }
  scope :with_specialty, ->(specialty) { where(specialty: specialty) if specialty.present? }

  def full_name
    "Dr #{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  def fee
    consultation_fee_cents / 100.0
  end

  def specialty_label
    specialty.humanize
  end

  # Next BOOKING_DAYS working days from tomorrow.
  def self.booking_days(from: Time.zone.tomorrow)
    days = []
    day = from
    while days.size < BOOKING_DAYS
      days << day unless day.saturday? || day.sunday?
      day += 1
    end
    days
  end

  # Free half-hour slots per day, booked ones removed. One query.
  def free_slots
    days = self.class.booking_days
    range = days.first.beginning_of_day..days.last.end_of_day
    booked = appointments.where(starts_at: range).where.not(status: "cancelled").pluck(:starts_at).to_set
    days.to_h do |day|
      slots = SLOT_TIMES.map { |h, m| Time.zone.local(day.year, day.month, day.day, h, m) }
      [day, slots.reject { |t| booked.include?(t) }]
    end
  end

  # Earliest free slot for each practitioner in the list. One query for the whole page.
  def self.next_available_slots(practitioners)
    ids = practitioners.map(&:id)
    return {} if ids.empty?

    days = booking_days
    range = days.first.beginning_of_day..days.last.end_of_day
    booked = Appointment.where(practitioner_id: ids, starts_at: range).where.not(status: "cancelled")
                        .pluck(:practitioner_id, :starts_at)
                        .group_by(&:first).transform_values { |rows| rows.map(&:last).to_set }
    candidates = days.flat_map { |d| SLOT_TIMES.map { |h, m| Time.zone.local(d.year, d.month, d.day, h, m) } }
    ids.to_h do |id|
      taken = booked[id] || Set.new
      [id, candidates.find { |t| !taken.include?(t) }]
    end
  end
end
