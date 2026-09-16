require "rails_helper"

RSpec.describe Bus, type: :model do
  describe "associations" do
    it "belongs to an operator" do
      association = described_class.reflect_on_association(:operator)

      expect(association.macro).to eq(:belongs_to)
    end

    it "has many seats" do
      association = described_class.reflect_on_association(:seats)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many trips" do
      association = described_class.reflect_on_association(:trips)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end
  end

  describe "validations" do
    it "requires a name" do
      bus = Bus.new(
        operator: Operator.new,
        bus_type: :ac_sleeper
      )

      expect(bus).not_to be_valid
      expect(bus.errors[:name]).to include("can't be blank")
    end

    it "requires a bus_type" do
      bus = Bus.new(
        operator: Operator.new,
        name: "Test Bus"
      )

      expect(bus).not_to be_valid
      expect(bus.errors[:bus_type]).to include("can't be blank")
    end

    it "is valid with a name and bus_type" do
      bus = Bus.new(
        operator: Operator.new,
        name: "Test Bus",
        bus_type: :ac_sleeper
      )

      bus.valid?

      expect(bus.errors[:name]).to be_empty
      expect(bus.errors[:bus_type]).to be_empty
    end
  end

  describe "bus_type enum" do
    it "has ac_sleeper" do
      expect(Bus.bus_types["ac_sleeper"]).to eq(0)
    end

    it "has ac_seater" do
      expect(Bus.bus_types["ac_seater"]).to eq(1)
    end

    it "has non_ac_sleeper" do
      expect(Bus.bus_types["non_ac_sleeper"]).to eq(2)
    end

    it "has non_ac_seater" do
      expect(Bus.bus_types["non_ac_seater"]).to eq(3)
    end
  end

  describe "dependent behavior" do
    it "destroys seats when the bus is destroyed" do
      association = described_class.reflect_on_association(:seats)

      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "restricts destruction when trips exist" do
      association = described_class.reflect_on_association(:trips)

      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end
  end
end
