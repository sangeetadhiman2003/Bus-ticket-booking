# db/seeds.rb

puts "Cleaning existing data..."

Booking.delete_all
TripSeat.delete_all
Hold.delete_all
Trip.delete_all
Seat.delete_all
Bus.delete_all
Operator.delete_all
User.delete_all

puts "Creating users..."

users = User.create!(
  [
    {
      email: "sangeeta@example.com",
      password: "password123",
      password_confirmation: "password123"
    },
    {
      email: "rahul@example.com",
      password: "password123",
      password_confirmation: "password123"
    },
    {
      email: "priya@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  ]
)

puts "Creating operators..."

operator1 = Operator.create!(
  name: "City Express",
  rating: 4.5
)

operator2 = Operator.create!(
  name: "Blue Line Travels",
  rating: 4.0
)

operator3 = Operator.create!(
  name: "Royal Bus Service",
  rating: 4.8
)

puts "Creating buses..."

bus1 = operator1.buses.create!(
  name: "City Express Volvo",
  bus_type: :ac_sleeper,
  amenities: {
    wifi: true,
    charging_point: true,
    water_bottle: true
  }
)

bus2 = operator1.buses.create!(
  name: "City Express Deluxe",
  bus_type: :non_ac_seater,
  amenities: {
    wifi: false,
    charging_point: true,
    water_bottle: true
  }
)

bus3 = operator2.buses.create!(
  name: "Blue Line AC Sleeper",
  bus_type: :ac_sleeper,
  amenities: {
    wifi: true,
    charging_point: true,
    blanket: true
  }
)

bus4 = operator2.buses.create!(
  name: "Blue Line Express",
  bus_type: :ac_seater,
  amenities: {
    wifi: true,
    charging_point: false,
    water_bottle: true
  }
)

bus5 = operator3.buses.create!(
  name: "Royal Luxury Sleeper",
  bus_type: :ac_sleeper,
  amenities: {
    wifi: true,
    charging_point: true,
    blanket: true,
    water_bottle: true
  }
)

puts "Creating seats..."

def create_seats(bus, count)
  (1..count).each do |number|
    bus.seats.create!(
      seat_number: "S#{number}"
    )
  end
end

create_seats(bus1, 20)
create_seats(bus2, 30)
create_seats(bus3, 20)
create_seats(bus4, 30)
create_seats(bus5, 20)

puts "Creating trips..."

base_time = Time.current

trips = []

trips << operator1.trips.create!(
  bus: bus1,
  from_city: "Indore",
  to_city: "Bhopal",
  departure_at: base_time.advance(days: 1).change(hour: 8, min: 0),
  arrival_at: base_time.advance(days: 1).change(hour: 11, min: 0),
  price: 700
)

trips << operator1.trips.create!(
  bus: bus2,
  from_city: "Indore",
  to_city: "Bhopal",
  departure_at: base_time.advance(days: 1).change(hour: 14, min: 0),
  arrival_at: base_time.advance(days: 1).change(hour: 17, min: 30),
  price: 450
)

trips << operator2.trips.create!(
  bus: bus3,
  from_city: "Indore",
  to_city: "Bhopal",
  departure_at: base_time.advance(days: 2).change(hour: 21, min: 0),
  arrival_at: base_time.advance(days: 3).change(hour: 1, min: 0),
  price: 850
)

trips << operator2.trips.create!(
  bus: bus4,
  from_city: "Indore",
  to_city: "Jabalpur",
  departure_at: base_time.advance(days: 2).change(hour: 7, min: 0),
  arrival_at: base_time.advance(days: 2).change(hour: 15, min: 0),
  price: 900
)

trips << operator3.trips.create!(
  bus: bus5,
  from_city: "Bhopal",
  to_city: "Jabalpur",
  departure_at: base_time.advance(days: 3).change(hour: 20, min: 0),
  arrival_at: base_time.advance(days: 4).change(hour: 5, min: 0),
  price: 1100
)

trips << operator3.trips.create!(
  bus: bus5,
  from_city: "Indore",
  to_city: "Mumbai",
  departure_at: base_time.advance(days: 4).change(hour: 19, min: 0),
  arrival_at: base_time.advance(days: 5).change(hour: 10, min: 0),
  price: 1500
)

puts "Creating trip seats..."

trips.each do |trip|
  trip.bus.seats.find_each do |seat|
    trip.trip_seats.create!(
      seat: seat,
      status: :available
    )
  end
end

puts "Seed completed successfully!"
