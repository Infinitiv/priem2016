class Campaign < ActiveRecord::Base
  has_many :admission_volumes
  has_many :distributed_admission_volumes, through: :admission_volumes
  
  validates :name, :year_start, :year_end, :status_id, :campaign_type_id, :education_forms, :education_levels, presence: true
  validates :year_start, :year_end, numericality: { only_integer: true }
  validates :year_start, :year_end, length: { is: 4 }
end