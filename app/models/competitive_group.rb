class CompetitiveGroup < ActiveRecord::Base
  belongs_to :campaign
  has_one :competitive_group_item, dependent: :destroy
  has_many :target_numbers, dependent: :destroy
  has_many :target_organizations, through: :target_numbers
  has_and_belongs_to_many :edu_programs
  has_and_belongs_to_many :entrance_test_items
  has_and_belongs_to_many :entrant_applications
  has_many :marks, through: :entrant_applications
  
  validates :campaign_id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id, presence: true
  validates :campaign_id, :education_level_id, :education_source_id, :education_form_id, :direction_id, numericality: {only_integer: true}
end