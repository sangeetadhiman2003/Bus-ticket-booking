require "rails_helper"

RSpec.describe "Bookings", type: :request do
  let!(:user) do
    User.create!(
      email: "sangeeta@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:operator) do
    Operator.create!(
      name: "City Express",
      rating: 4.5
    )
  end

  let!(:bus) do
    Bus.create!(
      operator: operator,
      name: "City Express Volvo",
      bus_type: :ac_sleeper,
      amenities: {
        wifi: true,
        charging_point: true,
        water_bottle: true
      }
    )
  end

  let!(:seat_1) do
    Seat.create!(
      bus: bus,
      seat_number: "S1"
    )
  end

  let!(:seat_2) do
    Seat.create!(
      bus: bus,
      seat_number: "S2"
    )
  end

  let!(:trip) do
    Trip.create!(
      operator: operator,
      bus: bus,
      from_city: "Indore",
      to_city: "Bhopal",
      departure_at: 2.days.from_now,
      arrival_at: 2.days.from_now + 3.hours,
      price: 500
    )
  end

  let!(:trip_seat_1) do
    TripSeat.create!(
      trip: trip,
      seat: seat_1,
      status: :available
    )
  end

  let!(:trip_seat_2) do
    TripSeat.create!(
      trip: trip,
      seat: seat_2,
      status: :available
    )
  end

  before do
    sign_in user
  end

  describe "GET /bookings" do
    it "returns successful response" do
      get bookings_path

      expect(response).to have_http_status(:ok)
    end

    it "shows current user's bookings" do
      hold = Hold.create!(
        user: user,
        trip: trip,
        expires_at: 1.hour.from_now,
        status: :confirmed
      )

      booking = Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        status: :confirmed,
        total_amount: 1000,
        idempotency_key: SecureRandom.uuid
      )

      get bookings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(booking.id.to_s)
    end
  end

  describe "GET /bookings/:id" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 1.hour.from_now,
        status: :confirmed
      )
    end

    let!(:booking) do
      Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        status: :confirmed,
        total_amount: 1000,
        idempotency_key: SecureRandom.uuid
      )
    end

    before do
      trip_seat_1.update!(
        status: :booked,
        hold: hold
      )

      trip_seat_2.update!(
        status: :booked,
        hold: hold
      )
    end

    it "returns successful response" do
      get booking_path(booking)

      expect(response).to have_http_status(:ok)
    end

    it "does not allow another user's hold" do
      another_user = User.create!(
        email: "rahul@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      another_hold = Hold.create!(
        user: another_user,
        trip: trip,
        expires_at: 5.minutes.from_now,
        status: :active
      )

      post bookings_path,
          params: {
            hold_id: another_hold.id,
            idempotency_key: SecureRandom.uuid
          }

      expect(response).to have_http_status(:not_found)
    end

  end

  describe "POST /bookings" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 5.minutes.from_now,
        status: :active
      )
    end

    before do
      trip_seat_1.update!(
        status: :held,
        hold: hold,
        held_until: hold.expires_at
      )

      trip_seat_2.update!(
        status: :held,
        hold: hold,
        held_until: hold.expires_at
      )
    end

    it "creates a booking" do
      expect do
        post bookings_path,
             params: {
               hold_id: hold.id,
               idempotency_key: SecureRandom.uuid
             }
      end.to change(Booking, :count).by(1)

      expect(response).to redirect_to(
        booking_path(Booking.last)
      )
    end

    it "shows success message" do
      post bookings_path,
           params: {
             hold_id: hold.id,
             idempotency_key: SecureRandom.uuid
           }

      expect(flash[:notice]).to eq(
        "Booking confirmed successfully."
      )
    end

    it "changes held seats to booked" do
      post bookings_path,
           params: {
             hold_id: hold.id,
             idempotency_key: SecureRandom.uuid
           }

      expect(trip_seat_1.reload.status).to eq("booked")
      expect(trip_seat_2.reload.status).to eq("booked")
    end

    it "confirms the hold" do
      post bookings_path,
           params: {
             hold_id: hold.id,
             idempotency_key: SecureRandom.uuid
           }

      expect(hold.reload).to be_confirmed
    end

    it "calculates total amount correctly" do
      post bookings_path,
           params: {
             hold_id: hold.id,
             idempotency_key: SecureRandom.uuid
           }

      booking = Booking.last

      expect(booking.total_amount.to_d).to eq(
        (trip.price * 2).to_d
      )
    end

    it "does not create booking without idempotency key" do
      expect do
        post bookings_path,
             params: {
               hold_id: hold.id
             }
      end.not_to change(Booking, :count)

      expect(response).to redirect_to(
        hold_path(hold)
      )

      expect(flash[:alert]).to eq(
        "Idempotency key is required."
      )
    end

    it "does not allow another user's hold" do
      another_user = User.create!(
        email: "rahul@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      another_hold = Hold.create!(
        user: another_user,
        trip: trip,
        expires_at: 5.minutes.from_now,
        status: :active
      )

      post bookings_path,
          params: {
            hold_id: another_hold.id,
            idempotency_key: SecureRandom.uuid
          }

      expect(response).to have_http_status(:not_found)
    end

    it "does not allow an expired hold" do
      hold.update!(
        expires_at: 1.minute.ago
      )

      expect do
        post bookings_path,
             params: {
               hold_id: hold.id,
               idempotency_key: SecureRandom.uuid
             }
      end.not_to change(Booking, :count)

      expect(response).to redirect_to(
        hold_path(hold)
      )

      expect(flash[:alert]).to eq(
        "This hold has expired."
      )
    end
  end

  describe "DELETE /bookings/:id" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 1.hour.from_now,
        status: :confirmed
      )
    end

    let!(:booking) do
      Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        status: :confirmed,
        total_amount: 1000,
        idempotency_key: SecureRandom.uuid
      )
    end

    it "cancels booking" do
      delete booking_path(booking)

      expect(response).to redirect_to(bookings_path)
      expect(booking.reload).to be_cancelled
    end

    it "sets cancelled_at" do
      delete booking_path(booking)

      expect(booking.reload.cancelled_at).to be_present
    end

    it "calculates refund amount" do
      delete booking_path(booking)

      expect(
        booking.reload.refund_amount.to_d
      ).to eq(950.to_d)
    end

    it "shows success message" do
      delete booking_path(booking)

      expect(flash[:notice]).to eq(
        "Booking cancelled successfully."
      )
    end

    it "does not cancel booking within one hour of departure" do
      trip.update!(
        departure_at: 30.minutes.from_now
      )

      delete booking_path(booking)

      expect(booking.reload).to be_confirmed

      expect(response).to redirect_to(
        booking_path(booking)
      )

      expect(flash[:alert]).to eq(
        "Cancellation is allowed only at least 1 hour before departure."
      )
    end

    it "does not cancel an already cancelled booking" do
      booking.update!(
        status: :cancelled
      )

      delete booking_path(booking)

      expect(response).to redirect_to(
        booking_path(booking)
      )

      expect(flash[:alert]).to eq(
        "Booking is already cancelled."
      )
    end
  end

  describe "GET /bookings/:id/reschedule" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 1.hour.from_now,
        status: :confirmed
      )
    end

    let!(:booking) do
      Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        status: :confirmed,
        total_amount: 1000,
        idempotency_key: SecureRandom.uuid
      )
    end

    let!(:new_bus) do
      Bus.create!(
        operator: operator,
        name: "City Express Deluxe",
        bus_type: :non_ac_seater,
        amenities: {
          wifi: false,
          charging_point: true,
          water_bottle: true
        }
      )
    end

    let!(:new_seat_1) do
      Seat.create!(
        bus: new_bus,
        seat_number: "S1"
      )
    end

    let!(:new_seat_2) do
      Seat.create!(
        bus: new_bus,
        seat_number: "S2"
      )
    end

    let!(:new_trip) do
      Trip.create!(
        operator: operator,
        bus: new_bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 3.days.from_now,
        arrival_at: 3.days.from_now + 3.hours,
        price: 600
      )
    end

    let!(:new_trip_seat_1) do
      TripSeat.create!(
        trip: new_trip,
        seat: new_seat_1,
        status: :available
      )
    end

    let!(:new_trip_seat_2) do
      TripSeat.create!(
        trip: new_trip,
        seat: new_seat_2,
        status: :available
      )
    end

    before do
      trip_seat_1.update!(
        status: :booked,
        hold: hold
      )

      trip_seat_2.update!(
        status: :booked,
        hold: hold
      )
    end

    it "returns successful response" do
      get reschedule_booking_path(booking)

      expect(response).to have_http_status(:ok)
    end

    it "shows current seats" do
      get reschedule_booking_path(booking)

      expect(response.body).to include("S1")
      expect(response.body).to include("S2")
    end

    it "shows the new trip" do
      get reschedule_booking_path(booking)

      expect(response.body).to include(
        new_trip.departure_at.strftime("%d %b %Y")
      )
    end

    it "does not allow cancelled booking" do
      booking.update!(
        status: :cancelled
      )

      get reschedule_booking_path(booking)

      expect(response).to redirect_to(
        booking_path(booking)
      )

      expect(flash[:alert]).to eq(
        "Only confirmed bookings can be rescheduled."
      )
    end
  end

  describe "PATCH /bookings/:id/update_reschedule" do
    let!(:hold) do
      Hold.create!(
        user: user,
        trip: trip,
        expires_at: 1.hour.from_now,
        status: :confirmed
      )
    end

    let!(:booking) do
      Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        status: :confirmed,
        total_amount: 1000,
        idempotency_key: SecureRandom.uuid
      )
    end

    let!(:new_bus) do
      Bus.create!(
        operator: operator,
        name: "City Express Deluxe",
        bus_type: :non_ac_seater,
        amenities: {
          wifi: false,
          charging_point: true,
          water_bottle: true
        }
      )
    end

    let!(:new_seat_1) do
      Seat.create!(
        bus: new_bus,
        seat_number: "S1"
      )
    end

    let!(:new_seat_2) do
      Seat.create!(
        bus: new_bus,
        seat_number: "S2"
      )
    end

    let!(:new_trip) do
      Trip.create!(
        operator: operator,
        bus: new_bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 3.days.from_now,
        arrival_at: 3.days.from_now + 3.hours,
        price: 600
      )
    end

    let!(:new_trip_seat_1) do
      TripSeat.create!(
        trip: new_trip,
        seat: new_seat_1,
        status: :available
      )
    end

    let!(:new_trip_seat_2) do
      TripSeat.create!(
        trip: new_trip,
        seat: new_seat_2,
        status: :available
      )
    end

    before do
      trip_seat_1.update!(
        status: :booked,
        hold: hold
      )

      trip_seat_2.update!(
        status: :booked,
        hold: hold
      )
    end

    it "redirects when trip is missing" do
      patch update_reschedule_booking_path(booking)

      expect(response).to redirect_to(
        reschedule_booking_path(booking)
      )

      expect(flash[:alert]).to eq(
        "Please select a trip."
      )
    end

    it "redirects when trip does not exist" do
      patch update_reschedule_booking_path(booking),
            params: {
              trip_id: 999_999
            }

      expect(response).to redirect_to(bookings_path)
    end

    it "reschedules booking to selected trip" do
      allow_any_instance_of(
        Bookings::RescheduleService
      ).to receive(:call)
        .and_return(booking)

      patch update_reschedule_booking_path(booking),
            params: {
              trip_id: new_trip.id
            }

      expect(response).to redirect_to(
        booking_path(booking)
      )

      expect(flash[:notice]).to eq(
        "Booking rescheduled successfully."
      )
    end
  end

  describe "authentication" do
    before do
      sign_out user
    end

    it "requires authentication for index" do
      get bookings_path

      expect(response).to redirect_to(
        new_user_session_path
      )
    end

    it "requires authentication for show" do
      get booking_path(1)

      expect(response).to redirect_to(
        new_user_session_path
      )
    end

    it "requires authentication for create" do
      post bookings_path,
           params: {
             hold_id: 1,
             idempotency_key: SecureRandom.uuid
           }

      expect(response).to redirect_to(
        new_user_session_path
      )
    end

    it "requires authentication for cancellation" do
      delete booking_path(1)

      expect(response).to redirect_to(
        new_user_session_path
      )
    end

    it "requires authentication for reschedule" do
      get reschedule_booking_path(1)

      expect(response).to redirect_to(
        new_user_session_path
      )
    end
  end
end
