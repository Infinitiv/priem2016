class AddAttachmentToIdentityDocument < ActiveRecord::Migration
  def change
    add_reference :identity_documents, :attachment, index: true, foreign_key: true
    add_column :identity_documents, :status, :string
  end
end
