module Bookings
  class RescheduleService
    def initialize(user:, booking:, new_trip:)
      @user = user
      @booking = booking
      @new_trip = new_trip
    end

    def call
      Booking.transaction do
        booking = lock_booking
        new_trip = lock_new_trip

        validate_booking!(booking)
        validate_new_trip!(booking, new_trip)

        old_hold = lock_old_hold!(booking)

        old_trip_seats = lock_old_trip_seats!(old_hold)

        validate_old_seats!(old_trip_seats)

        seat_ids = old_trip_seats.map(&:seat_id)

        new_trip_seats = lock_new_trip_seats(
          new_trip,
          seat_ids
        )

        validate_new_trip_seats!(
          new_trip_seats,
          seat_ids
        )

        make_expired_holds_available!(
          new_trip_seats
        )

        validate_new_seats_available!(
          new_trip_seats
        )

        new_hold = create_new_hold!(
          new_trip
        )

        book_new_seats!(
          new_trip_seats,
          new_hold
        )

        release_old_seats!(
          old_trip_seats
        )

        cancel_old_hold!(
          old_hold
        )

        update_booking!(
          booking,
          new_trip,
          new_hold,
          seat_ids.size
        )

        invalidate_trip_cache(booking.trip)
        invalidate_trip_cache(new_trip)

        booking
      end
    end

    private

    attr_reader :user, :booking, :new_trip

    # --------------------------------------------------
    # BOOKING
    # --------------------------------------------------

    def lock_booking
      Booking
        .lock
        .includes(:trip)
        .find(booking.id)
    end

    def validate_booking!(booking)
      unless booking.user_id == user.id
        raise UnauthorizedBookingError,
              "You cannot modify this booking."
      end

      unless booking.confirmed?
        raise InvalidBookingError,
              "Only confirmed bookings can be rescheduled."
      end
    end

    # --------------------------------------------------
    # NEW TRIP
    # --------------------------------------------------

    def lock_new_trip
      Trip
        .lock
        .find(new_trip.id)
    end

    def validate_new_trip!(booking, new_trip)
      old_trip = booking.trip

      if old_trip.id == new_trip.id
        raise InvalidBookingError,
              "Please select a different trip."
      end

      if new_trip.departure_at <= Time.current
        raise InvalidBookingError,
              "The selected trip has already departed."
      end

      unless old_trip.operator_id == new_trip.operator_id
        raise InvalidBookingError,
              "You can only reschedule with the same operator."
      end

      unless old_trip.from_city == new_trip.from_city &&
             old_trip.to_city == new_trip.to_city
        raise InvalidBookingError,
              "You can only reschedule on the same route."
      end
    end

    # --------------------------------------------------
    # OLD HOLD
    # --------------------------------------------------

    def lock_old_hold!(booking)
      hold = Hold
        .lock
        .find_by(id: booking.hold_id)

      unless hold
        raise InvalidBookingError,
              "Your booking does not have a valid seat hold."
      end

      hold
    end

    # --------------------------------------------------
    # OLD SEATS
    # --------------------------------------------------

    def lock_old_trip_seats!(old_hold)
      TripSeat
        .where(hold_id: old_hold.id)
        .lock
        .includes(:seat)
        .to_a
    end

    def validate_old_seats!(trip_seats)
      if trip_seats.empty?
        raise InvalidBookingError,
              "Your booking does not have any confirmed seats."
      end
    end

    # --------------------------------------------------
    # NEW SEATS
    # --------------------------------------------------

    def lock_new_trip_seats(new_trip, seat_ids)
      TripSeat
        .where(
          trip_id: new_trip.id,
          seat_id: seat_ids
        )
        .lock
        .includes(:seat)
        .to_a
    end

    def validate_new_trip_seats!(trip_seats, seat_ids)
      found_seat_ids = trip_seats.map(&:seat_id)

      missing_seat_ids = seat_ids - found_seat_ids

      return if missing_seat_ids.empty?

      raise InvalidBookingError,
            "One or more of your current seats do not exist on the selected trip."
    end

    # --------------------------------------------------
    # EXPIRED HOLDS
    # --------------------------------------------------

    def make_expired_holds_available!(trip_seats)
      trip_seats.each do |trip_seat|
        next unless trip_seat.held?

        next unless trip_seat.held_until.present?

        next if trip_seat.held_until > Time.current

        trip_seat.update!(
          status: :available,
          hold_id: nil,
          held_until: nil
        )
      end
    end

    # --------------------------------------------------
    # AVAILABILITY
    # --------------------------------------------------

    def validate_new_seats_available!(trip_seats)
      unavailable_seats = trip_seats.reject do |trip_seat|
        trip_seat.available?
      end

      return if unavailable_seats.empty?

      seat_numbers = unavailable_seats
        .map { |trip_seat| trip_seat.seat.seat_number }
        .join(", ")

      raise SeatUnavailableError,
            "Seat(s) #{seat_numbers} are already booked or temporarily held."
    end

    # --------------------------------------------------
    # CREATE NEW HOLD
    # --------------------------------------------------

    def create_new_hold!(trip)
      Hold.create!(
        user: user,
        trip: trip,
        status: :converted,
        expires_at: Time.current
      )
    end

    # --------------------------------------------------
    # BOOK NEW SEATS
    # --------------------------------------------------

    def book_new_seats!(trip_seats, hold)
      trip_seats.each do |trip_seat|
        trip_seat.update!(
          status: :booked,
          hold_id: hold.id,
          held_until: nil
        )
      end
    end

    # --------------------------------------------------
    # RELEASE OLD SEATS
    # --------------------------------------------------

    def release_old_seats!(trip_seats)
      trip_seats.each do |trip_seat|
        trip_seat.update!(
          status: :available,
          hold_id: nil,
          held_until: nil
        )
      end
    end

    # --------------------------------------------------
    # CANCEL OLD HOLD
    # --------------------------------------------------

    def cancel_old_hold!(old_hold)
      old_hold.update!(
        status: :cancelled
      )
    end

    # --------------------------------------------------
    # UPDATE BOOKING
    # --------------------------------------------------

    def update_booking!(
      booking,
      new_trip,
      new_hold,
      seat_count
    )
      booking.update!(
        trip_id: new_trip.id,
        hold_id: new_hold.id,
        total_amount: new_trip.price * seat_count
      )
    end

    # --------------------------------------------------
    # CACHE
    # --------------------------------------------------

    def invalidate_trip_cache(_trip)
      Rails.cache.delete_matched("trip-search*")
    end
  end
end
