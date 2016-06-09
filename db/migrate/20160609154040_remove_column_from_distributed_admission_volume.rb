class RemoveColumnFromDistributedAdmissionVolume < ActiveRecord::Migration
  def change
    remove_column :distributed_admission_volumes, :number_paid_o
    remove_column :distributed_admission_volumes, :number_paid_oz
    remove_column :distributed_admission_volumes, :number_paid_z
  end
end
