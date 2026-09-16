require "rails_helper"

RSpec.describe Operator, type: :model do
  describe "associations" do
    it "has many buses" do
      association = described_class.reflect_on_association(:buses)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end

    it "has many trips" do
      association = described_class.reflect_on_association(:trips)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:restrict_with_exception)
    end
  end

  describe "validations" do
    it "requires a name" do
      operator = Operator.new(
        rating: 4.5
      )

      expect(operator).not_to be_valid
      expect(operator.errors[:name]).to include("can't be blank")
    end

    it "allows a rating of 0" do
      operator = Operator.new(
        name: "Test Operator",
        rating: 0
      )

      operator.valid?

      expect(operator.errors[:rating]).to be_empty
    end

    it "allows a rating of 5" do
      operator = Operator.new(
        name: "Test Operator",
        rating: 5
      )

      operator.valid?

      expect(operator.errors[:rating]).to be_empty
    end

    it "allows a rating between 0 and 5" do
      operator = Operator.new(
        name: "Test Operator",
        rating: 4.5
      )

      operator.valid?

      expect(operator.errors[:rating]).to be_empty
    end

    it "does not allow a negative rating" do
      operator = Operator.new(
        name: "Test Operator",
        rating: -1
      )

      expect(operator).not_to be_valid
      expect(operator.errors[:rating]).to include(
        "must be greater than or equal to 0"
      )
    end

    it "does not allow a rating greater than 5" do
      operator = Operator.new(
        name: "Test Operator",
        rating: 6
      )

      expect(operator).not_to be_valid
      expect(operator.errors[:rating]).to include(
        "must be less than or equal to 5"
      )
    end
  end

  describe "valid operator" do
    it "is valid with a name and rating" do
      operator = Operator.new(
        name: "City Express",
        rating: 4.5
      )

      expect(operator).to be_valid
    end
  end
end
