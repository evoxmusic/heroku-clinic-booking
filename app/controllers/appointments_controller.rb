class AppointmentsController < ApplicationController
  def create
    practitioner = Practitioner.find(params[:practitioner_id])

    if params[:starts_at].blank?
      redirect_to practitioner, alert: "Choose a time slot first." and return
    end
    starts_at = Time.zone.parse(params[:starts_at])
    if starts_at.nil? || starts_at < Time.current
      redirect_to practitioner, alert: "That time slot is in the past." and return
    end
    if practitioner.appointments.where(starts_at: starts_at).where.not(status: "cancelled").exists?
      redirect_to practitioner, alert: "That slot was just taken. Pick another one." and return
    end
    if practitioner.appointments.where(starts_at: starts_at.all_day).count >= CLINIC[:max_bookings_per_day]
      redirect_to practitioner, alert: "No slots left on #{starts_at.strftime('%A %-d %B')}." and return
    end

    patient = Patient.find_or_create_by!(email: params.require(:email).strip.downcase) do |p|
      p.first_name = params[:first_name].presence || "Guest"
      p.last_name = params[:last_name].presence || "Patient"
      p.phone = params[:phone].presence
    end

    appointment = practitioner.appointments.create!(patient: patient, starts_at: starts_at, notes: params[:notes])
    AppointmentConfirmationJob.perform_later(appointment.id)
    redirect_to practitioner,
                notice: "Booked with #{practitioner.full_name} on #{starts_at.strftime('%A %-d %B at %H:%M')}. A confirmation is on its way to #{patient.email}."
  end
end
