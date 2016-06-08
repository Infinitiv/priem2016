class CreateCompetitiveGroupItems < ActiveRecord::Migration
  def change
    create_table :competitive_group_items do |t|
      t.references :competitive_group
      t.integer :number_budget_o, default: 0
      t.integer :number_budget_oz, default: 0
      t.integer :number_budget_z, default: 0
      t.integer :number_paid_o, default: 0
      t.integer :number_paid_oz, default: 0
      t.integer :number_paid_z, default: 0
      t.integer :number_target_o, default: 0
      t.integer :number_target_oz, default: 0
      t.integer :number_target_z, default: 0
      t.integer :number_quota_o, default: 0
      t.integer :number_quota_oz, default: 0
      t.integer :number_quota_z, default: 0

      t.timestamps
    end
    add_index :competitive_group_items, :competitive_group_id
  end
end
