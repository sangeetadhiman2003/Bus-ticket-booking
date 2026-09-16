require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it "has many holds" do
      association = described_class.reflect_on_association(:holds)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many bookings" do
      association = described_class.reflect_on_association(:bookings)

      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "Devise validations" do
    it "requires an email" do
      user = User.new(
        password: "password123",
        password_confirmation: "password123"
      )

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a password" do
      user = User.new(
        email: "test@example.com"
      )

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires a valid email format" do
      user = User.new(
        email: "invalid-email",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires password confirmation to match" do
      user = User.new(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "different-password"
      )

      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include(
        "doesn't match Password"
      )
    end

    it "is valid with valid attributes" do
      user = User.new(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(user).to be_valid
    end
  end

  describe "email uniqueness" do
    it "does not allow duplicate emails" do
      User.create!(
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      duplicate_user = User.new(
        email: "test@example.com",
        password: "password456",
        password_confirmation: "password456"
      )

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include(
        "has already been taken"
      )
    end
  end

  describe "Devise modules" do
    it "uses database authentication" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "uses registration" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "uses password recovery" do
      expect(User.devise_modules).to include(:recoverable)
    end

    it "uses rememberable" do
      expect(User.devise_modules).to include(:rememberable)
    end

    it "uses validatable" do
      expect(User.devise_modules).to include(:validatable)
    end
  end
end
