class CreateOperators < ActiveRecord::Migration[7.1]
  def change
    create_table :operators do |t|
      t.string :name
      t.decimal :rating

      t.timestamps
    end
  end
end
