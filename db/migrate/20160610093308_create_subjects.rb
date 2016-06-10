class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.integer :subject_id
      t.string :subject_name

      t.timestamps null: false
    end
  end
end
