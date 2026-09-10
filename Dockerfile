# syntax=docker/dockerfile:1
# Production image for the clinic-booking Rails 8 app (Ruby 3.3.12).
# Same image runs the web (Puma) and worker (Sidekiq) services on Qovery.

FROM ruby:3.3.12-slim AS builder

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential git libpq-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems first for better layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

# Copy the app and precompile assets (propshaft + importmap, no Node needed)
COPY . .
RUN SECRET_KEY_BASE=placeholder_for_assets bundle exec rails assets:precompile

# ---- Runtime image ----
FROM ruby:3.3.12-slim

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=enabled \
    RAILS_SERVE_STATIC_FILES=enabled \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends libpq5 libyaml-0-2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r appgroup && useradd -r -g appgroup -d /app appuser

WORKDIR /app

# Bundled gems and precompiled app from the builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

RUN chmod +x bin/qovery-entrypoint && \
    mkdir -p tmp log storage && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

ENTRYPOINT ["bin/qovery-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
