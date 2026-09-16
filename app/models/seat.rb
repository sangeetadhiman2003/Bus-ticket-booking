class Seat < ApplicationRecord
  belongs_to :bus

  has_many :trip_seats, dependent: :restrict_with_exception

  validates :seat_number,
            presence: true,
            uniqueness: {
              scope: :bus_id
            }
end
