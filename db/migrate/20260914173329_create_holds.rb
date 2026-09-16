class CreateHolds < ActiveRecord::Migration[7.1]
  def change
    create_table :holds do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.datetime :expires_at
      t.integer :status

      t.timestamps
    end
  end
end
