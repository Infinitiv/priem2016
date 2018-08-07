class Achievement < ActiveRecord::Base
  belongs_to :entrant_application
  belongs_to :institution_achievement

  validates :value, numericality: true
  
  def self.import_from_row(row, entrant_application)
    institution_achievements = entrant_application.campaign.institution_achievements
    accessible_attributes = institution_achievements.map(&:name)
    achievements = entrant_application.achievements
    row_achievements = row.slice(*accessible_attributes)
    row_achievements.each do |row_achievement_name, row_achievement_value|
      institution_achievement = institution_achievements.find_by_name(row_achievement_name)
      achievement = achievements.find_by_institution_achievement_id(institution_achievement.id) || achievements.new(institution_achievement_id: institution_achievement.id)
      achievement.value = row_achievement_value.to_f < institution_achievement.max_value ? row_achievement_value.to_f : institution_achievement.max_value
      achievement.save!
    end
  end
end
