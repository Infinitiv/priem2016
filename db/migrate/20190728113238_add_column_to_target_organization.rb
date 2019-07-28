class AddColumnToTargetOrganization < ActiveRecord::Migration
  def change
    add_column :target_organizations, :region_id, :integer
  end
end
