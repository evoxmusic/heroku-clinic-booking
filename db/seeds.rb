
# Seeds sized by SEED_APPOINTMENTS (default 800_000, about 260 MB with indexes on Postgres).
# Review apps set it lower through app.json. Idempotent: each step skips when its data is already there.
# Reset everything with: bin/rails runner "Appointment.delete_all; Patient.delete_all; Practitioner.delete_all" && bin/rails db:seed
require "faker"

target = ENV.fetch("SEED_APPOINTMENTS", "800000").to_i
Faker::Config.locale = "fr"
Faker::Config.random = Random.new(42)
cities = %w[Paris Lyon Marseille Toulouse Nantes Bordeaux Lille Strasbourg Rennes Montpellier]

BIO_TEMPLATES = [
  "%{specialty} in %{city} since %{year}. Graduated from the Faculté de Médecine de %{school}. Welcomes new patients and sees children from age %{age}.",
  "Practising %{specialty_lc} for %{years} years, first at the CHU de %{school}, now in a group practice in %{city}. Consultations in French and English.",
  "%{specialty}, former hospital practitioner at the CHU de %{school}. Focus on prevention and follow-up care. Same-week appointments for urgent cases.",
  "Member of the Ordre des Médecins since %{year}. %{specialty} in central %{city}, accessible practice, teleconsultation available for follow-ups."
].freeze
SCHOOLS = %w[Paris Lyon Marseille Bordeaux Lille Toulouse Nantes Strasbourg Montpellier Rennes].freeze

def build_bio(specialty, city)
  year = rand(1998..2019)
  format(BIO_TEMPLATES.sample,
         specialty: specialty.humanize, specialty_lc: specialty.humanize.downcase, city: city,
         year: year, years: 2026 - year, school: SCHOOLS.sample, age: [0, 3, 6].sample)
end

if Practitioner.count.zero?
  puts "Seeding practitioners..."
  rows = 2_000.times.map do
    specialty = Practitioner::SPECIALTIES.sample
    city = cities.sample
    { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
      specialty: specialty, city: city,
      address: Faker::Address.street_address, consultation_fee_cents: [2500, 3000, 5000, 6000, 8000, 12000].sample,
      bio: build_bio(specialty, city), created_at: Time.current, updated_at: Time.current }
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

practitioner_count = Practitioner.count
patient_count = Patient.count

# Historical appointments, the bulk of the data volume.
history_target = target
existing = Appointment.where("starts_at < ?", Time.current).count
if existing < history_target
  puts "Seeding #{history_target - existing} historical appointments..."
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO appointments (practitioner_id, patient_id, starts_at, duration_minutes, status, notes, created_at, updated_at)
    SELECT (SELECT min(id) FROM practitioners) + (g % #{practitioner_count}),
           (SELECT min(id) FROM patients) + (g % #{patient_count}),
           now() - interval '400 days' + (g % 399) * interval '1 day' + (9 + (g % 9)) * interval '1 hour' + ((g / 9) % 2) * interval '30 minutes',
           (ARRAY[15, 30, 45, 60])[1 + g % 4],
           (ARRAY['done', 'done', 'done', 'done', 'cancelled'])[1 + g % 5],
           'Visit ' || g || ': ' || repeat(md5(g::text), 4),
           now(), now()
    FROM generate_series(#{existing + 1}, #{history_target}) AS g;
  SQL
end

# Upcoming bookings on the consultation grid (09:00 to 17:30, working days, next 3 weeks),
# so availability varies per practitioner and per day. Roughly 70% of slots taken, busier in the mornings.
if Appointment.where("starts_at > ?", Time.current).count < 1000
  puts "Seeding upcoming bookings on the slot grid..."
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO appointments (practitioner_id, patient_id, starts_at, duration_minutes, status, notes, created_at, updated_at)
    SELECT p.id,
           (SELECT min(id) FROM patients) + ((p.id * 31 + s.n) % #{patient_count}),
           (((current_date + d.n) + make_interval(hours => 9) + s.n * interval '30 minutes') AT TIME ZONE 'Europe/Paris') AT TIME ZONE 'UTC',
           30,
           CASE WHEN (hashtext(p.id::text || ':' || d.n || ':' || s.n || ':status') & 1023) < 870 THEN 'confirmed' ELSE 'booked' END,
           'Upcoming visit',
           now(), now()
    FROM practitioners p
    CROSS JOIN generate_series(1, 21) AS d(n)
    CROSS JOIN generate_series(0, 17) AS s(n)
    WHERE extract(isodow from current_date + d.n) < 6
      -- deterministic per (practitioner, day, slot); random() would be evaluated once per (day, slot) before the join
      AND ((hashtext(p.id::text || ':' || d.n || ':' || s.n) & 1023) / 1024.0) < (CASE WHEN s.n < 8 THEN 0.8 ELSE 0.6 END) - (d.n / 60.0);
  SQL
end

ActiveRecord::Base.connection.execute("ANALYZE appointments;")
puts "Done: #{Practitioner.count} practitioners, #{Patient.count} patients, #{Appointment.count} appointments (#{Appointment.where('starts_at > ?', Time.current).count} upcoming)."
