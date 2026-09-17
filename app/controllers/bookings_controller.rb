class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_booking, only: [
    :show,
    :destroy,
    :reschedule,
    :update_reschedule
  ]

  def index
    @bookings = current_user.bookings
      .includes(
        :trip,
        hold: {
          trip_seats: :seat
        }
      )
      .order(created_at: :desc)
  end

  def show
    @booking = current_user.bookings
      .includes(
        :trip,
        hold: {
          trip_seats: :seat
        }
      )
      .find(@booking.id)
  end

  def create
    hold = current_user.holds.find(params[:hold_id])

    @booking = Bookings::CreateService.new(
      user: current_user,
      hold: hold,
      idempotency_key: params[:idempotency_key]
    ).call

    redirect_to booking_path(@booking),
                notice: "Booking confirmed successfully."

  rescue InvalidHoldError,
         UnauthorizedHoldError,
         ArgumentError => e

    redirect_to hold_path(params[:hold_id]),
                alert: e.message
  end

  def destroy
    Bookings::CancelService.new(
      user: current_user,
      booking: @booking
    ).call

    redirect_to bookings_path,
                notice: "Booking cancelled successfully."

  rescue CancellationNotAllowedError,
         InvalidBookingError => e

    redirect_to booking_path(@booking),
                alert: e.message
  end

  # GET /bookings/:id/reschedule
  def reschedule
    unless @booking.confirmed?
      redirect_to booking_path(@booking),
                  alert: "Only confirmed bookings can be rescheduled."
      return
    end

    @current_seats = @booking.hold
      .trip_seats
      .includes(:seat)
      .order(:id)

    if @current_seats.empty?
      redirect_to booking_path(@booking),
                  alert: "No seats are associated with this booking."
      return
    end

    @trips = available_reschedule_trips
  end

  # PATCH /bookings/:id/update_reschedule
  def update_reschedule
    if params[:trip_id].blank?
      redirect_to reschedule_booking_path(@booking),
                  alert: "Please select a trip."
      return
    end

    new_trip = Trip.find(params[:trip_id])

    updated_booking = Bookings::RescheduleService.new(
      user: current_user,
      booking: @booking,
      new_trip: new_trip
    ).call

    redirect_to booking_path(updated_booking),
                notice: "Booking rescheduled successfully."

  rescue ActiveRecord::RecordNotFound => e
    redirect_to bookings_path,
                alert: "Booking or trip not found."

  rescue SeatUnavailableError,
         InvalidBookingError,
         UnauthorizedBookingError,
         ArgumentError => e

    redirect_to reschedule_booking_path(@booking),
                alert: e.message
  end

  private

  def set_booking
    @booking = current_user.bookings.find(params[:id])
  end

  def available_reschedule_trips
    current_trip = @booking.trip

    Trip
      .where(
        operator_id: current_trip.operator_id,
        from_city: current_trip.from_city,
        to_city: current_trip.to_city
      )
      .where.not(id: current_trip.id)
      .where("departure_at > ?", Time.current)
      .includes(:operator, :bus)
      .order(:departure_at)
  end
end
