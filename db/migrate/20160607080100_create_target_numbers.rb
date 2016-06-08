class CreateTargetNumbers < ActiveRecord::Migration
  def change
    create_table :target_numbers do |t|
      t.references :target_organization, index: true, foreign_key: true
      t.references :competitive_group, index: true, foreign_key: true
      t.integer :number_target_o, default: 0
      t.integer :number_target_oz, default: 0
      t.integer :number_target_z, default: 0

      t.timestamps null: false
    end
  end
end
