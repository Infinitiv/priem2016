class CreateAdmissionVolumes < ActiveRecord::Migration
  def change
    create_table :admission_volumes do |t|
      t.references :campaign
      t.integer :education_level_id
      t.integer :direction_id
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
    add_index :admission_volumes, :campaign_id
  end
end
