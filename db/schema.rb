# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_04_090200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes", default: 30, null: false
    t.text "notes"
    t.bigint "patient_id", null: false
    t.bigint "practitioner_id", null: false
    t.datetime "reminded_at"
    t.datetime "starts_at", null: false
    t.string "status", default: "booked", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["practitioner_id", "starts_at"], name: "index_appointments_on_practitioner_id_and_starts_at"
    t.index ["practitioner_id"], name: "index_appointments_on_practitioner_id"
    t.index ["starts_at"], name: "index_appointments_on_starts_at"
  end

  create_table "patients", force: :cascade do |t|
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_patients_on_email", unique: true
  end

  create_table "practitioners", force: :cascade do |t|
    t.string "address"
    t.text "bio"
    t.string "city", null: false
    t.integer "consultation_fee_cents", default: 6000, null: false
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "specialty", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_practitioners_on_city"
    t.index ["specialty"], name: "index_practitioners_on_specialty"
  end

  add_foreign_key "appointments", "patients"
  add_foreign_key "appointments", "practitioners"
end
