module Bookings
  class CreateService
    def initialize(user:, hold:, idempotency_key:)
      @user = user
      @hold = hold
      @idempotency_key = idempotency_key
    end

    def call
      validate_idempotency_key!

      # Idempotency:
      # If this request was already processed, return
      # the existing booking instead of creating another one.
      existing_booking = Booking.find_by(
        idempotency_key: @idempotency_key
      )

      return existing_booking if existing_booking

      Booking.transaction do
        # Lock the hold so two confirmation requests
        # cannot confirm the same hold simultaneously.
        hold = Hold
          .lock
          .includes(trip_seats: :seat)
          .find(@hold.id)

        validate_hold!(hold)

        # Lock all seats belonging to this hold.
        trip_seats = hold.trip_seats
          .lock
          .includes(:seat)
          .to_a

        validate_trip_seats!(trip_seats)

        # Calculate total based on the number of seats.
        total_amount =
          hold.trip.price * trip_seats.size

        # Create exactly ONE booking for the entire hold.
        booking = Booking.create!(
          user_id: @user.id,
          trip_id: hold.trip_id,
          hold_id: hold.id,
          total_amount: total_amount,
          status: :confirmed,
          idempotency_key: @idempotency_key
        )

        # Convert every held seat into a booked seat.
        trip_seats.each do |trip_seat|
          trip_seat.update!(
            status: :booked,
            held_until: nil
          )
        end

        # Convert the hold into a confirmed hold.
        hold.update!(
          status: :confirmed
        )

        # Seat availability has changed.
        invalidate_trip_cache(hold.trip)

        booking
      end

    rescue ActiveRecord::RecordNotUnique
      # Handles two simultaneous requests using
      # the same idempotency key.
      Booking.find_by!(
        idempotency_key: @idempotency_key
      )
    end

    private

    def validate_idempotency_key!
      return if @idempotency_key.present?

      raise ArgumentError,
            "Idempotency key is required."
    end

    def validate_hold!(hold)
      # Make sure the hold belongs to the current user.
      unless hold.user_id == @user.id
        raise UnauthorizedHoldError,
              "You cannot use this hold."
      end

      # A hold can only be confirmed once.
      unless hold.active?
        raise InvalidHoldError,
              "This hold is no longer active."
      end

      # Check the five-minute expiry.
      if hold.expired?
        hold.update!(
          status: :expired
        )

        raise InvalidHoldError,
              "This hold has expired."
      end
    end

    def validate_trip_seats!(trip_seats)
      # A hold without seats cannot be converted
      # into a booking.
      if trip_seats.empty?
        raise InvalidHoldError,
              "This hold has no seats."
      end

      # Every seat belonging to this hold must still
      # have the status "held".
      unavailable_seats = trip_seats.reject(&:held?)

      return if unavailable_seats.empty?

      seat_numbers = unavailable_seats
        .map { |trip_seat| trip_seat.seat.seat_number }
        .join(", ")

      raise SeatUnavailableError,
            "Seat(s) #{seat_numbers} are no longer held."
    end

    def invalidate_trip_cache(trip)
      Rails.cache.delete_matched(
        "trip-search*"
      )
    end
  end
end
