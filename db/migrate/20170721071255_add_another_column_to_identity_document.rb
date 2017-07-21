class AddAnotherColumnToIdentityDocument < ActiveRecord::Migration
  def change
    add_reference :identity_documents, :entrant_application, index: true, foreign_key: true
  end
end
