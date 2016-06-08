class CreateEntranceTestItems < ActiveRecord::Migration
  def change
    create_table :entrance_test_items do |t|
      t.references :competitive_group
      t.integer :entrance_test_type_id, default: 1
      t.integer :min_score
      t.integer :entrance_test_priority
      t.integer :subject_id
      t.string :subject_name

      t.timestamps
    end
  end
end
