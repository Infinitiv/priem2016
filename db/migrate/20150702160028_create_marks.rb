class CreateMarks < ActiveRecord::Migration
  def change
    create_table :marks do |t|
      t.references :entrant_application, index: true
      t.references :subject, index: true
      t.integer :value
      t.string :form
      t.date :checked

      t.timestamps
    end
  end
end
