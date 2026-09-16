class TripsController < ApplicationController
  def index
    @trips = Trips::SearchService.new(
      params: search_params
    ).call
  end

  def show
    @trip = Trip
      .includes(
        :operator,
        :bus,
        trip_seats: :seat
      )
      .find(params[:id])
  end

  private

  def search_params
    params.permit(
      :from_city,
      :to_city,
      :date,
      :min_rating,
      :min_price,
      :max_price,
      :bus_type,
      :amenity
    )
  end
end
