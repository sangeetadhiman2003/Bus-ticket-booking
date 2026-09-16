module Trips
  class SearchService
    CACHE_EXPIRY = 5.minutes

    def initialize(params:)
      @params = params
    end

    def call
      Rails.cache.fetch(
        cache_key,
        expires_in: CACHE_EXPIRY
      ) do
        search_trips
      end
    end

    private

    def search_trips
      trips = Trip.all

      trips = filter_by_route(trips)
      trips = filter_by_date(trips)
      trips = filter_by_rating(trips)
      trips = filter_by_price(trips)
      trips = filter_by_bus_type(trips)
      trips = filter_by_amenity(trips)

      trips
        .includes(:operator, :bus)
        .order(:departure_at)
        .to_a
    end

    def filter_by_route(trips)
      trips = trips.where(from_city: @params[:from_city]) if @params[:from_city].present?

      if @params[:to_city].present?
        trips = trips.where(to_city: @params[:to_city])
      end

      trips
    end

    def filter_by_date(trips)
      return trips if @params[:date].blank?

      date = Date.parse(@params[:date])

      trips.where(
        departure_at: date.beginning_of_day..date.end_of_day
      )
    rescue ArgumentError
      trips.none
    end

    def filter_by_rating(trips)
      return trips if @params[:min_rating].blank?

      trips
        .joins(:operator)
        .where(
          "operators.rating >= ?",
          @params[:min_rating]
        )
    end

    def filter_by_price(trips)
      if @params[:min_price].present?
        trips = trips.where(
          "trips.price >= ?",
          @params[:min_price]
        )
      end

      if @params[:max_price].present?
        trips = trips.where(
          "trips.price <= ?",
          @params[:max_price]
        )
      end

      trips
    end

    def filter_by_bus_type(trips)
      return trips if @params[:bus_type].blank?

      trips
        .joins(:bus)
        .where(buses: { bus_type: @params[:bus_type] })
    end

    def filter_by_amenity(trips)
      return trips if @params[:amenity].blank?

      trips.where(
        "trips.amenities ? :amenity",
        amenity: @params[:amenity]
      )
    end

    def cache_key
      [
        "trip-search",
        @params.to_h.sort.to_h
      ]
    end
  end
end
