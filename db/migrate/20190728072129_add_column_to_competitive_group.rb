class AddColumnToCompetitiveGroup < ActiveRecord::Migration
  def change
    add_column :competitive_groups, :last_admission_date, :date
  end
end
