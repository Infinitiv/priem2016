class CreateOtherDocuments < ActiveRecord::Migration
  def change
    create_table :other_documents do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.string :other_document_series
      t.string :other_document_number
      t.date :other_document_date
      t.string :other_document_issuer
      t.references :attachment, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
