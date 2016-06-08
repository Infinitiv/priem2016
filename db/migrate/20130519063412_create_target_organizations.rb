class CreateTargetOrganizations < ActiveRecord::Migration
  def change
    create_table :target_organizations do |t|
      t.string :target_organization_name, default: ""

      t.timestamps
    end
  end
end
