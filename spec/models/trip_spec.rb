require "rails_helper"

RSpec.describe Trip, type: :model do
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

  describe "associations" do
    it "belongs to an operator" do
      association = described_class.reflect_on_association(:operator)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a bus" do
      association = described_class.reflect_on_association(:bus)

      expect(association.macro).to eq(:belongs_to)
    end

    it "has many seats through trip_seats" do
      association = described_class.reflect_on_association(:seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:trip_seats)
    end

    it "has many trip_seats" do
      association = described_class.reflect_on_association(:trip_seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many holds" do
      association = described_class.reflect_on_association(:holds)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end

    it "has many bookings" do
      association = described_class.reflect_on_association(:bookings)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end
  end

  describe "validations" do
    it "requires from_city" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:from_city]).to include("can't be blank")
    end

    it "requires to_city" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:to_city]).to include("can't be blank")
    end

    it "requires departure_at" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:departure_at]).to include("can't be blank")
    end

    it "requires arrival_at" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        price: 500
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:arrival_at]).to include("can't be blank")
    end

    it "requires price" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:price]).to include("can't be blank")
    end

    it "does not allow price to be zero" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 0
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:price]).to include("must be greater than 0")
    end

    it "does not allow negative price" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: -100
      )

      expect(trip).not_to be_valid
      expect(trip.errors[:price]).to include("must be greater than 0")
    end

    it "is valid with valid attributes" do
      trip = Trip.new(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(trip).to be_valid
    end
  end

  describe ".upcoming" do
    it "returns trips with future departure times" do
      past_trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.ago,
        arrival_at: 1.day.ago + 3.hours,
        price: 500
      )

      future_trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(Trip.upcoming).to include(future_trip)
      expect(Trip.upcoming).not_to include(past_trip)
    end
  end

  describe ".from_city" do
    it "finds trips by departure city case-insensitively" do
      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(Trip.from_city("indore")).to include(trip)
      expect(Trip.from_city("INDORE")).to include(trip)
    end

    it "does not return trips from another city" do
      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(Trip.from_city("Mumbai")).not_to include(trip)
    end
  end

  describe ".to_city" do
    it "finds trips by destination city case-insensitively" do
      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(Trip.to_city("bhopal")).to include(trip)
      expect(Trip.to_city("BHOPAL")).to include(trip)
    end

    it "does not return trips to another city" do
      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      expect(Trip.to_city("Mumbai")).not_to include(trip)
    end
  end

  describe ".on_date" do
    it "returns trips departing on the specified date" do
      date = Date.current

      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: date.beginning_of_day + 10.hours,
        arrival_at: date.beginning_of_day + 13.hours,
        price: 500
      )

      expect(Trip.on_date(date)).to include(trip)
    end

    it "does not return trips from another date" do
      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 2.days.from_now,
        arrival_at: 2.days.from_now + 3.hours,
        price: 500
      )

      expect(Trip.on_date(Date.current)).not_to include(trip)
    end
  end
end
