module Holds
  class CreateService
    HOLD_DURATION = 5.minutes

    def initialize(user:, trip:, seat_ids:)
      @user = user
      @trip = trip
      @seat_ids = Array(seat_ids)
        .filter_map(&:presence)
        .map(&:to_i)
        .uniq
    end

    def call
      validate!

      Hold.transaction do
        trip_seats = locked_trip_seats

        validate_trip_seats!(trip_seats)
        release_expired_holds!(trip_seats)
        validate_availability!(trip_seats)

        hold = create_hold!

        mark_trip_seats_as_held!(trip_seats, hold)

        schedule_expiry!(hold)

        hold
      end
    end

    private

    def validate!
      return if @seat_ids.any?

      raise ArgumentError,
            "Please select at least one seat."
    end

    def locked_trip_seats
      TripSeat
        .where(
          trip_id: @trip.id,
          seat_id: @seat_ids
        )
        .order(:seat_id)
        .lock
        .includes(:seat)
        .to_a
    end

    def validate_trip_seats!(trip_seats)
      return if trip_seats.size == @seat_ids.size

      raise ArgumentError,
            "One or more selected seats are invalid."
    end

    def release_expired_holds!(trip_seats)
      current_time = Time.current

      trip_seats.each do |trip_seat|
        next unless trip_seat.held?
        next unless trip_seat.held_until.present?
        next if trip_seat.held_until > current_time

        trip_seat.update!(
          status: :available,
          hold_id: nil,
          held_until: nil
        )
      end
    end

    def validate_availability!(trip_seats)
      unavailable_seats = trip_seats.reject(&:available?)

      return if unavailable_seats.empty?

      seat_numbers = unavailable_seats
        .map { |trip_seat| trip_seat.seat.seat_number }
        .join(", ")

      raise SeatUnavailableError,
            "Seat(s) #{seat_numbers} are not available."
    end

    def create_hold!
      Hold.create!(
        user: @user,
        trip: @trip,
        expires_at: HOLD_DURATION.from_now,
        status: :active
      )
    end

    def mark_trip_seats_as_held!(trip_seats, hold)
      trip_seats.each do |trip_seat|
        trip_seat.update!(
          status: :held,
          hold: hold,
          held_until: hold.expires_at
        )
      end
    end

    def schedule_expiry!(hold)
      ExpireHoldJob
        .set(wait: HOLD_DURATION)
        .perform_later(hold.id)
    end
  end
end
