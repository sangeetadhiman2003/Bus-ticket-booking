class Hold < ApplicationRecord
  belongs_to :user
  belongs_to :trip

  has_one :booking
  has_many :trip_seats, dependent: :nullify
  has_many :seats, through: :trip_seats


  enum :status, {
    active: 0,
    expired: 1,
    confirmed: 2
  }

  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def active_and_valid?
    active? && !expired?
  end
end
