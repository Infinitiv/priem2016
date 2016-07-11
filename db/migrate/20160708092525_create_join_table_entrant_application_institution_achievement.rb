class CreateJoinTableEntrantApplicationInstitutionAchievement < ActiveRecord::Migration
  def change
    create_join_table :entrant_applications, :institution_achievements do |t|
      # t.index [:entrant_application_id, :institution_achievement_id]
      # t.index [:institution_achievement_id, :entrant_application_id]
    end
  end
end
