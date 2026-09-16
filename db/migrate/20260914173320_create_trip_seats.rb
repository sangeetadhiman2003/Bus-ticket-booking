class CreateTripSeats < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_seats do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true
      t.integer :status
      t.bigint :hold_id
      t.datetime :held_until

      t.timestamps
    end
  end
end
