class CreateTrips < ActiveRecord::Migration[7.1]
  def change
    create_table :trips do |t|
      t.references :operator, null: false, foreign_key: true
      t.references :bus, null: false, foreign_key: true
      t.string :from_city
      t.string :to_city
      t.datetime :departure_at
      t.datetime :arrival_at
      t.decimal :price

      t.timestamps
    end
  end
end
