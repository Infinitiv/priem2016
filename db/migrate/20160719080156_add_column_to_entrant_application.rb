class AddColumnToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :budget_agr, :integer
    add_column :entrant_applications, :paid_agr, :integer
  end
end
