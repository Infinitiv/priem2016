class RemoveColumnFromEntrantApplication < ActiveRecord::Migration
  def change
    remove_column :entrant_applications, :target_organization_id, :integer
  end
end
