class Campaign < ActiveRecord::Base
  validates :name, :year_start, :year_end, :status_id, :campaign_type_id, :education_forms, :education_levels, presence: true
  validates :year_start, :year_end, numericality: { only_integer: true }
  validates :year_start, :year_end, length: { is: 4 }
end