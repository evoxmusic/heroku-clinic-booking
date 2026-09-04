class AppointmentsController < ApplicationController
  def create
    practitioner = Practitioner.find(params[:practitioner_id])
    patient = Patient.find_or_create_by!(email: params.require(:email)) do |p|
      p.first_name = params.fetch(:first_name, "Guest")
      p.last_name = params.fetch(:last_name, "Patient")
    end

    starts_at = Time.zone.parse(params.require(:starts_at))
    same_day = practitioner.appointments.where(starts_at: starts_at.all_day).count
    if same_day >= CLINIC[:max_bookings_per_day]
      redirect_to practitioner, alert: "No slots left that day." and return
    end

    appointment = practitioner.appointments.create!(patient: patient, starts_at: starts_at, notes: params[:notes])
    AppointmentConfirmationJob.perform_later(appointment.id)
    redirect_to practitioner, notice: "Booked #{practitioner.full_name} at #{starts_at.strftime('%d %b %H:%M')}. Confirmation on its way."
  end
end
