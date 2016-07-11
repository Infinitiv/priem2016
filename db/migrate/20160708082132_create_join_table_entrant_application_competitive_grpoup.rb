class CreateJoinTableEntrantApplicationCompetitiveGrpoup < ActiveRecord::Migration
  def change
    create_join_table :entrant_applications, :competitive_groups do |t|
      # t.index [:entrant_application_id, :competitive_group_id]
      # t.index [:competitive_group_id, :entrant_application_id]
    end
  end
end
