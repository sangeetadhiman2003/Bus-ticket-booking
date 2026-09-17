## Completed

The application includes:

- User authentication
- Trip search and filtering
- Seat selection with 5-minute temporary holds
- Concurrency-safe seat booking
- Idempotent booking confirmation
- Booking rescheduling
- Booking cancellation and refund
- Background jobs for hold expiry
- Rails caching
- RSpec testing

## Clone and Run

git clone https://github.com/sangeetadhiman2003/Bus-ticket-booking
cd Bus-ticket-booking
bundle install

rails db:create
rails db:migrate
rails db:seed

rails server


Open:

http://localhost:3000

Run tests:
bundle exec rspec


### Requirements

* Ruby 3.2.2
* Rails 7.1.6
* PostgreSQL 12+
