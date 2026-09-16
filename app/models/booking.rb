class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :trip
  belongs_to :hold

  has_many :trip_seats, through: :hold
  has_many :seats, through: :trip_seats


  enum :status, {
    confirmed: 0,
    cancelled: 1
  }

  validates :total_amount,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :idempotency_key,
            presence: true,
            uniqueness: true
end
