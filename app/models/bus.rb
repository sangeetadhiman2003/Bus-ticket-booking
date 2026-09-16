class Bus < ApplicationRecord
  belongs_to :operator

  has_many :seats, dependent: :destroy
  has_many :trips, dependent: :restrict_with_exception

  enum :bus_type, {
    ac_sleeper: 0,
    ac_seater: 1,
    non_ac_sleeper: 2,
    non_ac_seater: 3
  }

  validates :name, presence: true
  validates :bus_type, presence: true
end
