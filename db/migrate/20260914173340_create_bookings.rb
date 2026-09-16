class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :status
      t.decimal :total_amount
      t.string :idempotency_key

      t.timestamps
    end
  end
end
