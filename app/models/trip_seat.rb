class TripSeat < ApplicationRecord
  belongs_to :trip
  belongs_to :seat
  belongs_to :hold, optional: true

  enum :status, {
    available: 0,
    held: 1,
    booked: 2
  }

  validates :seat_id,
            uniqueness: {
              scope: :trip_id
            }

  scope :available_seats, -> {
    where(status: :available)
  }
end
