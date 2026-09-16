class AddHoldToBookings < ActiveRecord::Migration[7.1]
  def change
    add_reference :bookings, :hold, null: true, foreign_key: true
  end
end
