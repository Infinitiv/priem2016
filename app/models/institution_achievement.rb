class InstitutionAchievement < ActiveRecord::Base
  belongs_to :campaign
  
  validates :name, :id_category, :max_value, :campaign_id, presence: true
  validates :id_category, :max_value, :campaign_id, numericality: {only_integer: true}
end