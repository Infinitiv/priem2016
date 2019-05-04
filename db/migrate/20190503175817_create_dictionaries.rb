class CreateDictionaries < ActiveRecord::Migration
  def change
    create_table :dictionaries do |t|
      t.string :name
      t.integer :code
      t.json :items

      t.timestamps null: false
    end
  end
end
