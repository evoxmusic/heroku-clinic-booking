# Heroku Redis (mini and above) requires TLS with a self-signed certificate,
# so verification has to be disabled. That is the kind of add-on quirk that
# has to be rediscovered when the add-on becomes something you operate.
redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server { |config| config.redis = redis_config }
Sidekiq.configure_client { |config| config.redis = redis_config }
