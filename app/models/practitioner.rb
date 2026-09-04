class Practitioner < ApplicationRecord
  has_many :appointments, dependent: :destroy

  SPECIALTIES = %w[
    general_practitioner dentist dermatologist cardiologist pediatrician
    gynecologist ophthalmologist physiotherapist psychiatrist osteopath
  ].freeze

  validates :first_name, :last_name, :specialty, :city, presence: true

  scope :in_city, ->(city) { where(city: city) if city.present? }
  scope :with_specialty, ->(specialty) { where(specialty: specialty) if specialty.present? }

  def full_name
    "Dr #{first_name} #{last_name}"
  end

  def fee
    consultation_fee_cents / 100.0
  end
end
