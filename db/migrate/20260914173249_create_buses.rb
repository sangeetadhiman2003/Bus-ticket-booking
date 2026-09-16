class CreateBuses < ActiveRecord::Migration[7.1]
  def change
    create_table :buses do |t|
      t.references :operator, null: false, foreign_key: true
      t.string :name
      t.integer :bus_type
      t.jsonb :amenities

      t.timestamps
    end
  end
end
