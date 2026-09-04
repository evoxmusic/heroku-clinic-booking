class PractitionersController < ApplicationController
  def index
    @specialty = params[:specialty].presence
    @city = params[:city].presence
    @practitioners = Practitioner.with_specialty(@specialty).in_city(@city).order(:last_name, :first_name).limit(40).to_a
    @next_slots = Practitioner.next_available_slots(@practitioners)
    @cities = Rails.cache.fetch("practitioner-cities", expires_in: 1.hour) { Practitioner.distinct.order(:city).pluck(:city) }
    @stats = Rails.cache.fetch("home-stats", expires_in: 10.minutes) do
      { practitioners: Practitioner.count, appointments: Appointment.count, cities: @cities.size }
    end
  end

  def show
    @practitioner = Practitioner.find(params[:id])
    @free_slots = @practitioner.free_slots
    @selected = params[:starts_at].presence
  end
end
