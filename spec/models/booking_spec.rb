require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "associations" do
    it "belongs to a user" do
      association = described_class.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a trip" do
      association = described_class.reflect_on_association(:trip)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a hold" do
      association = described_class.reflect_on_association(:hold)

      expect(association.macro).to eq(:belongs_to)
    end

    it "has many trip_seats through hold" do
      association = described_class.reflect_on_association(:trip_seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:hold)
    end

    it "has many seats through trip_seats" do
      association = described_class.reflect_on_association(:seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:trip_seats)
    end
  end

  describe "status enum" do
    it "has confirmed status" do
      expect(Booking.statuses["confirmed"]).to eq(0)
    end

    it "has cancelled status" do
      expect(Booking.statuses["cancelled"]).to eq(1)
    end
  end

  describe "total_amount validation" do
    it "allows zero" do
      booking = Booking.new(
        total_amount: 0,
        idempotency_key: "test-key"
      )

      booking.valid?

      expect(booking.errors[:total_amount]).to be_empty
    end

    it "allows positive values" do
      booking = Booking.new(
        total_amount: 500,
        idempotency_key: "test-key"
      )

      booking.valid?

      expect(booking.errors[:total_amount]).to be_empty
    end

    it "does not allow negative values" do
      booking = Booking.new(
        total_amount: -100,
        idempotency_key: "test-key"
      )

      expect(booking).not_to be_valid
      expect(booking.errors[:total_amount]).to include(
        "must be greater than or equal to 0"
      )
    end
  end

  describe "idempotency_key validation" do
    it "requires an idempotency_key" do
      booking = Booking.new(total_amount: 500)

      expect(booking).not_to be_valid
      expect(booking.errors[:idempotency_key]).to include("can't be blank")
    end

    it "accepts a unique idempotency_key" do
      booking = Booking.new(
        total_amount: 500,
        idempotency_key: "unique-key-123"
      )

      booking.valid?

      expect(booking.errors[:idempotency_key]).to be_empty
    end

    it "does not allow duplicate idempotency_key" do
      user = User.create!(
        email: "test@example.com",
        password: "password123"
      )

      operator = Operator.create!(
        name: "Test Operator",
        rating: 4.5
      )

      bus = Bus.create!(
        operator: operator,
        name: "Test Bus",
        bus_type: :ac_seater
      )

      trip = Trip.create!(
        operator: operator,
        bus: bus,
        from_city: "Indore",
        to_city: "Bhopal",
        departure_at: 1.day.from_now,
        arrival_at: 1.day.from_now + 3.hours,
        price: 500
      )

      hold = Hold.create!(
        user: user,
        trip: trip,
        expires_at: 10.minutes.from_now,
        status: :active
      )

      Booking.create!(
        user: user,
        trip: trip,
        hold: hold,
        total_amount: 500,
        idempotency_key: "duplicate-key"
      )

      duplicate_booking = Booking.new(
        user: user,
        trip: trip,
        hold: hold,
        total_amount: 600,
        idempotency_key: "duplicate-key"
      )

      expect(duplicate_booking).not_to be_valid
      expect(duplicate_booking.errors[:idempotency_key])
        .to include("has already been taken")
    end


  end
end
