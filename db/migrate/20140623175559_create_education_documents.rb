class CreateEducationDocuments < ActiveRecord::Migration
  def change
    create_table :education_documents do |t|
      t.references :entrant_application, index: true
      t.string :education_document_type
      t.string :education_document_number
      t.date :education_document_date
      t.date :original_received_date

      t.timestamps
    end
  end
end
