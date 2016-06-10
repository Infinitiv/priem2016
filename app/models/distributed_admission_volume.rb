class DistributedAdmissionVolume < ActiveRecord::Base
  belongs_to :admission_volume
  
  validates   :admission_volume_id, :level_budget_id, presence: true
  validates :admission_volume_id, :level_budget_id, :number_budget_o, :number_budget_oz, :number_budget_z, :number_target_o, :number_target_oz, :number_target_z, :number_quota_o, :number_quota_oz, :number_quota_z, numericality: {only_integer: true}
end