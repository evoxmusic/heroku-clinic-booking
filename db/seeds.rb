# Seeds sized by SEED_APPOINTMENTS (default 1_500_000, about 300 MB with indexes on Postgres 16).
# Review apps set it to 5_000 through app.json. Idempotent: skips when data is already there.
require "faker"

target = ENV.fetch("SEED_APPOINTMENTS", "1500000").to_i
if Appointment.count >= target
  puts "Seeds already present (#{Appointment.count} appointments), skipping."
  exit
end

Faker::Config.random = Random.new(42)
cities = %w[Paris Lyon Marseille Toulouse Nantes Bordeaux Lille Strasbourg Rennes Montpellier]

if Practitioner.count.zero?
  puts "Seeding practitioners..."
  rows = 2_000.times.map do
    { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
      specialty: Practitioner::SPECIALTIES.sample, city: cities.sample,
      address: Faker::Address.street_address, consultation_fee_cents: [2500, 3000, 5000, 6000, 8000, 12000].sample,
      bio: Faker::Lorem.paragraph(sentence_count: 3), created_at: Time.current, updated_at: Time.current }
  end
  Practitioner.insert_all(rows)
end

if Patient.count.zero?
  puts "Seeding patients..."
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO patients (first_name, last_name, email, phone, birth_date, created_at, updated_at)
    SELECT 'Patient', 'Number ' || g, 'patient' || g || '@example.com',
           '+3361' || lpad((g % 10000000)::text, 7, '0'),
           date '1950-01-01' + (g % 25000), now(), now()
    FROM generate_series(1, 50000) AS g;
  SQL
end

puts "Seeding appointments up to #{target} rows..."
practitioner_count = Practitioner.count
patient_count = Patient.count
existing = Appointment.count
ActiveRecord::Base.connection.execute(<<~SQL)
  INSERT INTO appointments (practitioner_id, patient_id, starts_at, duration_minutes, status, notes, created_at, updated_at)
  SELECT (SELECT min(id) FROM practitioners) + (g % #{practitioner_count}),
         (SELECT min(id) FROM patients) + (g % #{patient_count}),
         now() - interval '365 days' + (g % 730) * interval '12 hours' + (g % 16) * interval '30 minutes',
         (ARRAY[15, 30, 45, 60])[1 + g % 4],
         (ARRAY['booked', 'confirmed', 'cancelled', 'done', 'done', 'done'])[1 + g % 6],
         'Visit ' || g || ': ' || repeat(md5(g::text), 4),
         now(), now()
  FROM generate_series(#{existing + 1}, #{target}) AS g;
SQL
ActiveRecord::Base.connection.execute("ANALYZE appointments;")
puts "Done: #{Practitioner.count} practitioners, #{Patient.count} patients, #{Appointment.count} appointments."
