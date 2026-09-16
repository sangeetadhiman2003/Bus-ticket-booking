require "rails_helper"

RSpec.describe Hold, type: :model do
  describe "associations" do
    it "belongs to a user" do
      association = described_class.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to a trip" do
      association = described_class.reflect_on_association(:trip)

      expect(association.macro).to eq(:belongs_to)
    end

    it "has one booking" do
      association = described_class.reflect_on_association(:booking)

      expect(association.macro).to eq(:has_one)
    end

    it "has many trip_seats" do
      association = described_class.reflect_on_association(:trip_seats)

      expect(association.macro).to eq(:has_many)
    end

    it "has many seats through trip_seats" do
      association = described_class.reflect_on_association(:seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:trip_seats)
    end
  end

  describe "validations" do
    it "requires expires_at" do
      hold = Hold.new(
        user: User.new,
        trip: Trip.new
      )

      expect(hold).not_to be_valid
      expect(hold.errors[:expires_at]).to include("can't be blank")
    end

    it "is valid when expires_at is present" do
      hold = Hold.new(
        user: User.new,
        trip: Trip.new,
        expires_at: 10.minutes.from_now
      )

      # Only checking expires_at validation here.
      hold.valid?

      expect(hold.errors[:expires_at]).to be_empty
    end
  end

  describe "status enum" do
    it "has active status" do
      expect(Hold.statuses["active"]).to eq(0)
    end

    it "has expired status" do
      expect(Hold.statuses["expired"]).to eq(1)
    end

    it "has confirmed status" do
      expect(Hold.statuses["confirmed"]).to eq(2)
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      hold = Hold.new(expires_at: 1.minute.ago)

      expect(hold.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      hold = Hold.new(expires_at: 1.minute.from_now)

      expect(hold.expired?).to be false
    end
  end

  describe "#active_and_valid?" do
    it "returns true when active and not expired" do
      hold = Hold.new(
        status: :active,
        expires_at: 10.minutes.from_now
      )

      expect(hold.active_and_valid?).to be true
    end

    it "returns false when active but expired" do
      hold = Hold.new(
        status: :active,
        expires_at: 10.minutes.ago
      )

      expect(hold.active_and_valid?).to be false
    end

    it "returns false when status is expired" do
      hold = Hold.new(
        status: :expired,
        expires_at: 10.minutes.from_now
      )

      expect(hold.active_and_valid?).to be false
    end

    it "returns false when status is confirmed" do
      hold = Hold.new(
        status: :confirmed,
        expires_at: 10.minutes.from_now
      )

      expect(hold.active_and_valid?).to be false
    end
  end
end
