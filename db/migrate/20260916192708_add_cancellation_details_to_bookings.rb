class AddCancellationDetailsToBookings < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :cancelled_at, :datetime
    add_column :bookings, :refund_amount, :decimal,
               precision: 10,
               scale: 2,
               default: 0.0,
               null: false
  end
end
