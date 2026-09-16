require "rails_helper"

RSpec.describe TripSeat, type: :model do
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

  let!(:seat) do
    Seat.create!(
      bus: bus,
      seat_number: "S1"
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

  describe "associations" do
    it "belongs to a trip" do
      association = described_class.reflect_on_association(:trip)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a seat" do
      association = described_class.reflect_on_association(:seat)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a hold optionally" do
      association = described_class.reflect_on_association(:hold)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to eq(true)
    end
  end

  describe "validations" do
    it "does not allow the same seat on the same trip twice" do
      TripSeat.create!(
        trip: trip,
        seat: seat,
        status: :available
      )

      duplicate_trip_seat = TripSeat.new(
        trip: trip,
        seat: seat,
        status: :available
      )

      expect(duplicate_trip_seat).not_to be_valid
      expect(duplicate_trip_seat.errors[:seat_id]).to include(
        "has already been taken"
      )
    end

    it "allows the same seat on different trips" do
      TripSeat.create!(
        trip: trip,
        seat: seat,
        status: :available
      )

      another_trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Jabalpur",
        departure_at: 2.days.from_now,
        arrival_at: 2.days.from_now + 3.hours,
        price: 700
      )

      another_trip_seat = TripSeat.new(
        trip: another_trip,
        seat: seat,
        status: :available
      )

      expect(another_trip_seat).to be_valid
    end
  end

  describe "status enum" do
    it "has available status" do
      expect(TripSeat.statuses["available"]).to eq(0)
    end

    it "has held status" do
      expect(TripSeat.statuses["held"]).to eq(1)
    end

    it "has booked status" do
      expect(TripSeat.statuses["booked"]).to eq(2)
    end
  end

  describe ".available_seats" do
    it "returns only available trip seats" do
      available_seat = TripSeat.create!(
        trip: trip,
        seat: seat,
        status: :available
      )

      booked_seat_record = Seat.create!(
        bus: bus,
        seat_number: "S2"
      )

      booked_seat = TripSeat.create!(
        trip: trip,
        seat: booked_seat_record,
        status: :booked
      )

      held_seat_record = Seat.create!(
        bus: bus,
        seat_number: "S3"
      )

      held_seat = TripSeat.create!(
        trip: trip,
        seat: held_seat_record,
        status: :held
      )

      expect(TripSeat.available_seats).to include(available_seat)
      expect(TripSeat.available_seats).not_to include(booked_seat)
      expect(TripSeat.available_seats).not_to include(held_seat)
    end

    it "returns an empty collection when no seats are available" do
      booked_seat = Seat.create!(
        bus: bus,
        seat_number: "S2"
      )

      TripSeat.create!(
        trip: trip,
        seat: booked_seat,
        status: :booked
      )

      expect(TripSeat.available_seats).to be_empty
    end
  end
end
