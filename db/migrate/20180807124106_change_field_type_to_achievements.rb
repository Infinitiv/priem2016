class ChangeFieldTypeToAchievements < ActiveRecord::Migration
  def change
    change_column :achievements, :value, :float
  end
end
