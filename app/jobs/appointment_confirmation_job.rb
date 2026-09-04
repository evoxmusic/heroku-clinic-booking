class AppointmentConfirmationJob < ApplicationJob
  queue_as :default

  # In the real app this calls SendGrid. Here we log what would be sent,
  # which is enough to prove the worker dyno picks jobs up.
  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    provider = CLINIC[:sendgrid_api_key].present? ? "sendgrid" : "log-only"
    Rails.logger.info(
      "[confirmation] appointment=#{appointment.id} patient=#{appointment.patient.email} " \
      "practitioner=#{appointment.practitioner.full_name} at=#{appointment.starts_at.iso8601} via=#{provider}"
    )
    appointment.update!(status: "confirmed") if appointment.status == "booked"
  end
end
