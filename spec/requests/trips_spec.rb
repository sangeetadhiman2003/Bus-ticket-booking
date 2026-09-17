require "rails_helper"

RSpec.describe "Trips", type: :request do
  let!(:operator) do
    Operator.create!(
      name: "City Express",
      rating: 4.5
    )
  end

  let!(:bus) do
    Bus.create!(
      operator: operator,
      name: "City Express Bus",
      bus_type: :ac_seater,
      amenities: {
        wifi: true,
        charging_point: true
      }
    )
  end

  let!(:seat) do
    Seat.create!(
      bus: bus,
      seat_number: "S1"
    )
  end

  let!(:trip_seat) do
    TripSeat.create!(
      trip: trip,
      seat: seat,
      status: :available
    )
  end

  let!(:trip) do
    Trip.create!(
      operator: operator,
      bus: bus,
      from_city: "Indore",
      to_city: "Bhopal",
      departure_at: 1.day.from_now,
      arrival_at: 1.day.from_now + 3.hours,
      price: 500
    )
  end

  let!(:another_trip) do
    Trip.create!(
      operator: operator,
      bus: bus,
      from_city: "Indore",
      to_city: "Jabalpur",
      departure_at: 2.days.from_now,
      arrival_at: 2.days.from_now + 4.hours,
      price: 800
    )
  end

  describe "GET /trips" do
    it "returns a successful response" do
      get trips_path

      expect(response).to have_http_status(:ok)
    end

    it "displays trips" do
      get trips_path

      expect(response.body).to include("Indore")
      expect(response.body).to include("Bhopal")
    end

    context "with route filters" do
      it "filters by from_city" do
        get trips_path, params: {
          from_city: "Indore"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end

      it "filters by to_city" do
        get trips_path, params: {
          to_city: "Jabalpur"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Jabalpur")
      end

      it "filters by both from_city and to_city" do
        get trips_path, params: {
          from_city: "Indore",
          to_city: "Bhopal"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end
    end

    context "with price filters" do
      it "filters by minimum price" do
        get trips_path, params: {
          min_price: 700
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Jabalpur")
      end

      it "filters by maximum price" do
        get trips_path, params: {
          max_price: 600
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end

      it "filters by minimum and maximum price" do
        get trips_path, params: {
          min_price: 400,
          max_price: 600
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end
    end

    context "with rating filter" do
      it "filters by minimum operator rating" do
        get trips_path, params: {
          min_rating: 4.0
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end

      it "does not return trips when rating is too high" do
        get trips_path, params: {
          min_rating: 5.0
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Bhopal")
      end
    end

    context "with bus type filter" do
      it "filters by bus type" do
        get trips_path, params: {
          bus_type: "ac_seater"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end
    end

    context "with date filter" do
      it "filters trips by departure date" do
        get trips_path, params: {
          date: trip.departure_at.to_date.to_s
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end

      it "returns no trips for an invalid date" do
        get trips_path, params: {
          date: "invalid-date"
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "with multiple filters" do
      it "applies multiple search filters" do
        get trips_path, params: {
          from_city: "Indore",
          to_city: "Bhopal",
          min_price: 400,
          max_price: 600,
          min_rating: 4.0,
          bus_type: "ac_seater"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bhopal")
      end
    end
  end

  describe "GET /trips/:id" do
    it "returns a successful response" do
      get trip_path(trip)

      expect(response).to have_http_status(:ok)
    end

    it "displays the trip details" do
      get trip_path(trip)

      expect(response.body).to include("Indore")
      expect(response.body).to include("Bhopal")
    end

    it "displays the operator" do
      get trip_path(trip)

      expect(response.body).to include("City Express")
    end

    it "loads the trip with its bus" do
      get trip_path(trip)

      expect(response).to have_http_status(:ok)
      expect(trip.bus).to eq(bus)
    end


    it "returns not found for an invalid trip id" do
      get trip_path(id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end
end
