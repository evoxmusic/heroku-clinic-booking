class ReminderJob < ApplicationJob
  queue_as :default

  # Enqueued by Heroku Scheduler through `rake reminders:enqueue`.
  # Marks every appointment inside the reminder window as reminded.
  def perform
    count = 0
    Appointment.due_for_reminder.includes(:patient).find_each(batch_size: 500) do |appointment|
      Rails.logger.info("[reminder] appointment=#{appointment.id} patient=#{appointment.patient.email}")
      appointment.update_columns(reminded_at: Time.current)
      count += 1
    end
    Rails.logger.info("[reminder] sent=#{count}")
  end
end
