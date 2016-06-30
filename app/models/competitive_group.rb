class CompetitiveGroup < ActiveRecord::Base
  belongs_to :campaign
  has_one :competitive_group_item
  has_many :target_numbers
  has_many :target_organizations, through: :target_numbers
  has_and_belongs_to_many :edu_programs
  has_and_belongs_to_many :entrance_test_items
  
  validates :campaign_id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id, presence: true
  validates :campaign_id, :education_level_id, :education_source_id, :education_form_id, :direction_id, numericality: {only_integer: true}
end