class CreateAchievements < ActiveRecord::Migration
  def change
    create_table :achievements do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.references :institution_achievement, index: true, foreign_key: true
      t.integer :value, default: 0

      t.timestamps null: false
    end
  end
end
