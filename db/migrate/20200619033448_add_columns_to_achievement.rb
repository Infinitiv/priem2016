class AddColumnsToAchievement < ActiveRecord::Migration
  def change
    add_reference :achievements, :attachment, index: true, foreign_key: true
    add_column :achievements, :status, :string
  end
end
