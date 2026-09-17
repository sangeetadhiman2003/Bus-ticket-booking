class ExpireHoldJob < ApplicationJob
  queue_as :default

  def perform(hold_id)
    Hold.transaction do
      hold = Hold.lock.find_by(id: hold_id)

      return unless hold
      return unless hold.active?
      return unless hold.expired?

      hold.trip_seats.lock.each do |trip_seat|
        next unless trip_seat.held?
        next unless trip_seat.hold_id == hold.id

        trip_seat.update!(
          status: :available,
          hold_id: nil,
          held_until: nil
        )
      end

      hold.update!(
        status: :expired
      )
    end

    Rails.cache.delete_matched("trip-search*")
  end
end
