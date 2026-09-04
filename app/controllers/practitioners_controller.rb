class PractitionersController < ApplicationController
  def index
    @specialty = params[:specialty].presence
    @city = params[:city].presence
    @practitioners = Practitioner.with_specialty(@specialty).in_city(@city).order(:last_name).limit(50)
    @cities = Rails.cache.fetch("practitioner-cities", expires_in: 1.hour) { Practitioner.distinct.order(:city).pluck(:city) }
  end

  def show
    @practitioner = Practitioner.find(params[:id])
    @upcoming = @practitioner.appointments.upcoming.order(:starts_at).limit(10)
    @appointment = Appointment.new
  end
end
