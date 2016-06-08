class CreateJoinTableCompetitiveGroupEduProgram < ActiveRecord::Migration
  def change
    create_join_table :competitive_groups, :edu_programs do |t|
      # t.index [:competitive_group_id, :edu_program_id]
      # t.index [:edu_program_id, :competitive_group_id]
    end
  end
end
