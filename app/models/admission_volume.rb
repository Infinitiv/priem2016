class AdmissionVolume < ActiveRecord::Base
  belongs_to :campaign
  has_many :distributed_admission_volumes, dependent: :destroy
  
  validates :campaign_id, :education_level_id, :direction_id, presence: true
  validates :campaign_id, :education_level_id, :direction_id, :number_budget_o, :number_budget_oz, :number_budget_z, :number_paid_o, :number_paid_oz, :number_paid_z, :number_target_o, :number_target_oz, :number_target_z, :number_quota_o, :number_quota_oz, :number_quota_z, numericality: {only_integer: true}
end