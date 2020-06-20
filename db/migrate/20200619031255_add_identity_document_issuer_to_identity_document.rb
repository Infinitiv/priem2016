class AddIdentityDocumentIssuerToIdentityDocument < ActiveRecord::Migration
  def change
    add_column :identity_documents, :identity_document_issuer, :string
  end
end
