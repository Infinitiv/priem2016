class AddColumnToIdentityDocument < ActiveRecord::Migration
  def change
    add_column :identity_documents, :alt_entrant_last_name, :string
    add_column :identity_documents, :alt_entrant_first_name, :string
    add_column :identity_documents, :alt_entrant_middle_name, :string
  end
end
