class HoldsController < ApplicationController
  before_action :authenticate_user!

  def create
    holds = Holds::CreateService.new(
      user: current_user,
      trip: trip,
      seat_ids: hold_params[:seat_ids]
    ).call
    redirect_to hold_path(holds),
                notice: "Selected seats are held for 5 minutes."
  rescue SeatUnavailableError, ArgumentError => e
    redirect_to trip_path(trip),
                alert: e.message
  end

  def show
    @hold = current_user.holds
      .includes(:trip, trip_seats: :seat)
      .find(params[:id])
  end


  private

  def trip
    @trip ||= Trip.find(params[:trip_id])
  end

  def hold_params
    params.permit(seat_ids: [])
  end
end
