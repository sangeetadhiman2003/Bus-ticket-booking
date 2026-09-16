module Bookings
  class CancelService
    CANCELLATION_WINDOW = 1.hour
    CANCELLATION_FEE = 50

    def initialize(user:, booking:)
      @user = user
      @booking = booking
    end

    def call
      Booking.transaction do
        booking = Booking
          .lock
          .includes(:trip)
          .find(@booking.id)

        validate!(booking)

        booking.update!(
          status: :cancelled,
          cancelled_at: Time.current,
          refund_amount: calculate_refund(booking)
        )

        invalidate_trip_cache(booking.trip)

        booking
      end
    end

    private

    def validate!(booking)
      unless booking.user_id == @user.id
        raise UnauthorizedBookingError,
              "You cannot cancel this booking."
      end

      unless booking.confirmed?
        raise InvalidBookingError,
              "Booking is already cancelled."
      end

      if booking.trip.departure_at <= 1.hour.from_now
        raise CancellationNotAllowedError,
              "Cancellation is allowed only at least 1 hour before departure."
      end
    end

    def calculate_refund(booking)
      [
        booking.total_amount - CANCELLATION_FEE,
        0
      ].max
    end

    def invalidate_trip_cache(trip)
      Rails.cache.delete_matched(
        "trip-search*"
      )
    end
  end
end
