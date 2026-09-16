class BookingsController < ApplicationController
  before_action :authenticate_user!

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
      .find(params[:id])
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
    booking = current_user.bookings.find(params[:id])

    Bookings::CancelService.new(
      user: current_user,
      booking: booking
    ).call

    redirect_to bookings_path,
                notice: "Booking cancelled successfully."
  rescue CancellationNotAllowedError,
         InvalidBookingError => e

    redirect_to booking_path(booking),
                alert: e.message
  end

  def update_reschedule
    @booking = current_user.bookings.find(params[:id])

    new_trip = Trip.find(params[:trip_id])
    booking = Bookings::RescheduleService.new(
      user: current_user,
      booking: @booking,
      new_trip: new_trip
    ).call

    redirect_to booking_path(booking),
                notice: "Booking rescheduled successfully."

  rescue ActiveRecord::RecordNotFound
    redirect_to bookings_path,
                alert: "Booking or trip not found."

  rescue SeatUnavailableError,
         InvalidBookingError,
         UnauthorizedBookingError,
         ArgumentError => e

    redirect_to reschedule_booking_path(
      @booking,
      trip_id: params[:trip_id]
    ),
    alert: e.message
  end


  def reschedule
    @booking = current_user.bookings
      .includes(
        :hold,
        trip: [:operator, :bus]
      )
      .find(params[:id])

    unless @booking.confirmed?
      redirect_to booking_path(@booking),
                  alert: "Only confirmed bookings can be rescheduled."
      return
    end

    @current_seats = @booking.hold
      .trip_seats
      .includes(:seat)
      .order(:id)

    @trips = available_reschedule_trips

    @selected_trip =
      @trips.find_by(id: params[:trip_id]) if params[:trip_id].present?
  end

  private

  def reschedule_params
    params.permit(
      :trip_id,
      seat_ids: []
    )
  end
end
