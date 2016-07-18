class InstitutionAchievement < ActiveRecord::Base
  belongs_to :campaign
  has_and_belongs_to_many :entrant_applications
  
  validates :name, :id_category, :max_value, :campaign_id, presence: true
  validates :id_category, :max_value, :campaign_id, numericality: {only_integer: true}
  
  def self.import_from_row(row, entrant_application)
    
    achievement_8 = find_by_id_category(8)
    achievement_9 = find_by_id_category(9)
    achievement_17 = find_by_id_category(17)
    case row["achievement_att"]
    when '1'
      entrant_application.institution_achievements << achievement_9 unless entrant_application.institution_achievements.include?(achievement_9)
    else
      entrant_application.institution_achievements.delete(achievement_9) if entrant_application.institution_achievements.include?(achievement_9)
    end
    case row["achievement_dip"]
    when '1'
      entrant_application.institution_achievements << achievement_17 unless entrant_application.institution_achievements.include?(achievement_17)
    else
      entrant_application.institution_achievements.delete(achievement_17) if entrant_application.institution_achievements.include?(achievement_17)
    end
    case row["achievement_gto"]
    when '1'
      entrant_application.institution_achievements << achievement_8 unless entrant_application.institution_achievements.include?(achievement_8)
    else
      entrant_application.institution_achievements.delete(achievement_8) if entrant_application.institution_achievements.include?(achievement_8)
    end  
  end
end