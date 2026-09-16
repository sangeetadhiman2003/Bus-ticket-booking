require "rails_helper"

RSpec.describe Seat, type: :model do
  describe "associations" do
    it "belongs to a bus" do
      association = described_class.reflect_on_association(:bus)

      expect(association.macro).to eq(:belongs_to)
    end

    it "has many trip_seats" do
      association = described_class.reflect_on_association(:trip_seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end
  end

  describe "validations" do
    it "requires a seat_number" do
      seat = Seat.new

      expect(seat).not_to be_valid
      expect(seat.errors[:seat_number]).to include("can't be blank")
    end

    it "does not allow duplicate seat numbers on the same bus" do
      operator = Operator.create!(
        name: "Test Operator",
        rating: 4.5
      )

      bus = Bus.create!(
        operator: operator,
        name: "Test Bus",
        bus_type: :ac_seater
      )

      Seat.create!(
        bus: bus,
        seat_number: "S1"
      )

      duplicate_seat = Seat.new(
        bus: bus,
        seat_number: "S1"
      )

      expect(duplicate_seat).not_to be_valid
      expect(duplicate_seat.errors[:seat_number]).to include(
        "has already been taken"
      )
    end

    it "allows the same seat number on different buses" do
      operator = Operator.create!(
        name: "Test Operator",
        rating: 4.5
      )

      bus1 = Bus.create!(
        operator: operator,
        name: "Bus 1",
        bus_type: :ac_seater
      )

      bus2 = Bus.create!(
        operator: operator,
        name: "Bus 2",
        bus_type: :ac_seater
      )

      Seat.create!(
        bus: bus1,
        seat_number: "S1"
      )

      seat2 = Seat.new(
        bus: bus2,
        seat_number: "S1"
      )

      expect(seat2).to be_valid
    end
  end

end
