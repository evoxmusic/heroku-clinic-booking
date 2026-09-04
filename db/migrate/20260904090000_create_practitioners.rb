class CreatePractitioners < ActiveRecord::Migration[8.1]
  def change
    create_table :practitioners do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :specialty, null: false
      t.string :city, null: false
      t.string :address
      t.integer :consultation_fee_cents, null: false, default: 6000
      t.text :bio
      t.timestamps
    end
    add_index :practitioners, :specialty
    add_index :practitioners, :city
  end
end
