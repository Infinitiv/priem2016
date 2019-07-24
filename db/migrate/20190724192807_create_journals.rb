class CreateJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.references :user, index: true, foreign_key: true
      t.references :entrant_application, index: true, foreign_key: true
      t.string :method
      t.string :value_name
      t.string :old_value
      t.string :new_value

      t.timestamps null: false
    end
  end
end
