# Application settings, all read from config vars the Heroku way.
# Anything with a real value in production is a secret and lives only in the environment.
CLINIC = {
  app_host: ENV.fetch("APP_HOST", "localhost:3000"),
  support_email: ENV.fetch("SUPPORT_EMAIL", "support@clinic-booking.example"),
  reminder_hours_before: ENV.fetch("REMINDER_HOURS_BEFORE", "24").to_i,
  max_bookings_per_day: ENV.fetch("MAX_BOOKINGS_PER_DAY", "12").to_i,
  online_payment: ENV.fetch("FEATURE_ONLINE_PAYMENT", "false") == "true",
  stripe_secret_key: ENV["STRIPE_SECRET_KEY"],
  stripe_publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
  sendgrid_api_key: ENV["SENDGRID_API_KEY"],
  twilio_account_sid: ENV["TWILIO_ACCOUNT_SID"],
  twilio_auth_token: ENV["TWILIO_AUTH_TOKEN"],
  sentry_dsn: ENV["SENTRY_DSN"],
  maps_api_key: ENV["MAPS_API_KEY"]
}.freeze
