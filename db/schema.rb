# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_09_16_192708) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trip_id", null: false
    t.integer "status"
    t.decimal "total_amount"
    t.string "idempotency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "hold_id"
    t.datetime "cancelled_at"
    t.decimal "refund_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["hold_id"], name: "index_bookings_on_hold_id"
    t.index ["trip_id"], name: "index_bookings_on_trip_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "buses", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.string "name"
    t.integer "bus_type"
    t.jsonb "amenities"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_id"], name: "index_buses_on_operator_id"
  end

  create_table "holds", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trip_id", null: false
    t.datetime "expires_at"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_holds_on_trip_id"
    t.index ["user_id"], name: "index_holds_on_user_id"
  end

  create_table "operators", force: :cascade do |t|
    t.string "name"
    t.decimal "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "seats", force: :cascade do |t|
    t.bigint "bus_id", null: false
    t.string "seat_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_id"], name: "index_seats_on_bus_id"
  end

  create_table "trip_seats", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "seat_id", null: false
    t.integer "status"
    t.bigint "hold_id"
    t.datetime "held_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seat_id"], name: "index_trip_seats_on_seat_id"
    t.index ["trip_id"], name: "index_trip_seats_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.bigint "operator_id", null: false
    t.bigint "bus_id", null: false
    t.string "from_city"
    t.string "to_city"
    t.datetime "departure_at"
    t.datetime "arrival_at"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_id"], name: "index_trips_on_bus_id"
    t.index ["operator_id"], name: "index_trips_on_operator_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookings", "holds"
  add_foreign_key "bookings", "trips"
  add_foreign_key "bookings", "users"
  add_foreign_key "buses", "operators"
  add_foreign_key "holds", "trips"
  add_foreign_key "holds", "users"
  add_foreign_key "seats", "buses"
  add_foreign_key "trip_seats", "seats"
  add_foreign_key "trip_seats", "trips"
  add_foreign_key "trips", "buses"
  add_foreign_key "trips", "operators"
end
