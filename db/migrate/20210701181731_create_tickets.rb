class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.integer :parent_ticket
      t.text :message
      t.boolean :solved, default: false

      t.timestamps null: false
    end
  end
end
