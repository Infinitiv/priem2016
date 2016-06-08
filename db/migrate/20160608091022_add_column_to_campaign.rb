class AddColumnToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :education_forms, :integer, array: true
    add_column :campaigns, :education_levels, :integer, array: true
  end
end
