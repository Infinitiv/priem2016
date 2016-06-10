class CreateEntranceTestItems < ActiveRecord::Migration
  def change
    create_table :entrance_test_items do |t|
      t.integer :entrance_test_type_id, default: 1
      t.integer :min_score
      t.integer :entrance_test_priority
      t.references :subject

      t.timestamps
    end
  end
end
