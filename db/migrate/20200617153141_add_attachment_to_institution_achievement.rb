class AddAttachmentToInstitutionAchievement < ActiveRecord::Migration
  def change
    add_reference :institution_achievements, :attachment, index: true, foreign_key: true
    add_column :institution_achievements, :status, :string
  end
end
