class CreateInstitutionAchievements < ActiveRecord::Migration
  def change
    create_table :institution_achievements do |t|
      t.string :name
      t.integer :id_category
      t.integer :max_value
      t.references :campaign, index: true

      t.timestamps
    end
  end
end
