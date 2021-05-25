class AddColumnsToCompetitiveGroup < ActiveRecord::Migration
  def change
    add_column :competitive_groups, :application_start_date, :date
    add_column :competitive_groups, :application_end_exam_date, :date
    add_column :competitive_groups, :application_end_ege_date, :date
    add_column :competitive_groups, :order_end_date, :date
  end
end
