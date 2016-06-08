class CreateDistributedAdmissionVolumes < ActiveRecord::Migration
  def change
    create_table :distributed_admission_volumes do |t|
      t.references :admission_volume
      t.integer :level_budget_id
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
    add_index :distributed_admission_volumes, :admission_volume_id
  end
end
