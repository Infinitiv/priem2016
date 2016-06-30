class EntranceTestItem < ActiveRecord::Base
  has_and_belongs_to_many :competitive_group
  belongs_to :subject
  
  validates :entrance_test_type_id, :min_score, :entrance_test_priority, :subject_id, presence: true
end