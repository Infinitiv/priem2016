class AddEducationDocumentIssuerToEducationDocument < ActiveRecord::Migration
  def change
    add_column :education_documents, :education_document_issuer, :string
  end
end
