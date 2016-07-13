class CreateJoinTableEntrantApplicationsIdentityDocuments < ActiveRecord::Migration
  def change
    create_join_table :entrant_applications, :identity_documents do |t|
      # t.index [:entrant_application_id, :identity_document_id]
      # t.index [:identity_document_id, :entrant_application_id]
    end
  end
end
