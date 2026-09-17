require "rails_helper"

RSpec.describe "Holds", type: :request do
  let!(:user) do
    User.create!(
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:operator) do
    Operator.create!(
      name: "Test Operator",
      rating: 4.5
    )
  end

  let!(:bus) do
    Bus.create!(
      operator: operator,
      name: "Test Bus",
      bus_type: :ac_seater
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

  describe "POST /trips/:trip_id/holds" do
    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "creates a hold" do
        expect {
          post trip_holds_path(trip),
               params: {
                 seat_ids: [seat.id]
               }
        }.to change(Hold, :count).by(1)
      end

      it "redirects to the hold page" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        hold = Hold.last

        expect(response).to redirect_to(hold_path(hold))
      end

      it "sets a success notice" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(flash[:notice]).to eq(
          "Selected seats are held for 5 minutes."
        )
      end

      it "marks the seat as held" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(trip_seat.reload.status).to eq("held")
      end

      it "creates the hold for the current user" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(Hold.last.user).to eq(user)
      end

      it "creates the hold for the correct trip" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(Hold.last.trip).to eq(trip)
      end
    end

    context "when no seat is selected" do
      before do
        sign_in user
      end

      it "does not create a hold" do
        expect {
          post trip_holds_path(trip),
               params: {
                 seat_ids: []
               }
        }.not_to change(Hold, :count)
      end

      it "redirects to the trip page" do
        post trip_holds_path(trip),
             params: {
               seat_ids: []
             }

        expect(response).to redirect_to(trip_path(trip))
      end

      it "sets an error alert" do
        post trip_holds_path(trip),
             params: {
               seat_ids: []
             }

        expect(flash[:alert]).to eq(
          "Please select at least one seat."
        )
      end
    end

    context "when seat is invalid" do
      before do
        sign_in user
      end

      it "does not create a hold" do
        expect {
          post trip_holds_path(trip),
               params: {
                 seat_ids: [999_999]
               }
        }.not_to change(Hold, :count)
      end

      it "redirects to the trip page" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [999_999]
             }

        expect(response).to redirect_to(trip_path(trip))
      end

      it "sets an error alert" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [999_999]
             }

        expect(flash[:alert]).to eq(
          "One or more selected seats are invalid."
        )
      end
    end

    context "when seat is unavailable" do
      before do
        sign_in user
        trip_seat.update!(status: :booked)
      end

      it "does not create a hold" do
        expect {
          post trip_holds_path(trip),
               params: {
                 seat_ids: [seat.id]
               }
        }.not_to change(Hold, :count)
      end

      it "redirects to the trip page" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(response).to redirect_to(trip_path(trip))
      end

      it "sets an unavailable seat alert" do
        post trip_holds_path(trip),
             params: {
               seat_ids: [seat.id]
             }

        expect(flash[:alert]).to eq(
          "Seat(s) S1 are not available."
        )
      end
    end
  end

  describe "GET /holds/:id" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 5.minutes.from_now,
        status: :active
      )
    end

    context "when user is authenticated" do
      before do
        sign_in user
      end

      it "returns a successful response" do
        get hold_path(hold)

        expect(response).to have_http_status(:ok)
      end

      it "shows the user's hold" do
        get hold_path(hold)

        expect(response).to have_http_status(:ok)
      end

    end

    context "when user is not authenticated" do
      it "redirects to the login page" do
        get hold_path(hold)

        expect(response).to redirect_to(
          new_user_session_path
        )
      end
    end

    context "when hold belongs to another user" do
      let!(:other_user) do
        User.create!(
          email: "other@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
      end

      let!(:other_hold) do
        Hold.create!(
          user: other_user,
          trip: trip,
          expires_at: 5.minutes.from_now,
          status: :active
        )
      end

      before do
        sign_in user
      end

      it "returns not found" do
        get hold_path(other_hold)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
