class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :practitioner, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: false, default: 30
      t.string :status, null: false, default: "booked"
      t.text :notes
      t.datetime :reminded_at
      t.timestamps
    end
    add_index :appointments, [:practitioner_id, :starts_at]
    add_index :appointments, :starts_at
  end
end
