class Operator < ApplicationRecord
  has_many :buses, dependent: :restrict_with_exception
  has_many :trips, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :rating,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 5
            }
end
