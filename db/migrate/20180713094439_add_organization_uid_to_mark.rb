class AddOrganizationUidToMark < ActiveRecord::Migration
  def change
    add_column :marks, :organization_uid, :string, default: ''
  end
end
