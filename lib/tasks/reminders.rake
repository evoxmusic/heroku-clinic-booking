namespace :reminders do
  desc "Enqueue the reminder job. Called by Heroku Scheduler every 10 minutes."
  task enqueue: :environment do
    ReminderJob.perform_later
    puts "ReminderJob enqueued at #{Time.current.iso8601}"
  end
end
