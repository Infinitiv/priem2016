class RemoveColumnsFromInstitutionAchievement < ActiveRecord::Migration
  def change
    remove_reference :institution_achievements, :attachment, index: true, foreign_key: true
    remove_column :institution_achievements, :status, :string
  end
end
