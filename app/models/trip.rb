class Trip < ApplicationRecord
  belongs_to :operator
  belongs_to :bus

  has_many :seats, through: :trip_seats
  has_many :trip_seats, dependent: :destroy
  has_many :holds, dependent: :restrict_with_exception
  has_many :bookings, dependent: :restrict_with_exception

  validates :from_city, :to_city, presence: true
  validates :departure_at, :arrival_at, :price, presence: true

  validates :price,
            numericality: {
              greater_than: 0
            }

  scope :upcoming, -> {
    where("departure_at > ?", Time.current)
  }

  scope :from_city, ->(city) {
    where("LOWER(from_city) = ?", city.to_s.downcase)
  }

  scope :to_city, ->(city) {
    where("LOWER(to_city) = ?", city.to_s.downcase)
  }

  scope :on_date, ->(date) {
    where(
      departure_at:
        date.beginning_of_day..date.end_of_day
    )
  }
end
