class Campaign < ActiveRecord::Base
  has_many :admission_volumes, dependent: :destroy
  has_many :distributed_admission_volumes, through: :admission_volumes
  has_many :competitive_groups, dependent: :destroy
  has_many :competitive_group_items, through: :competitive_groups
  has_many :institution_achievements, dependent: :destroy
  has_many :entrant_applications, dependent: :destroy
  has_many :marks, through: :entrant_applications
  has_many :achievements, through: :entrant_applications
  
  validates :name, :year_start, :year_end, :status_id, :campaign_type_id, :education_forms, :education_levels, presence: true
  validates :year_start, :year_end, numericality: { only_integer: true }
  validates :year_start, :year_end, length: { is: 4 }
end
