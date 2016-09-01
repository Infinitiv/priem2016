class CreateBenefitDocuments < ActiveRecord::Migration
  def change
    create_table :benefit_documents do |t|
      t.integer :benefit_document_type_id
      t.string :benefit_document_series
      t.string :benefit_document_number
      t.date :benefit_document_date
      t.string :benefit_document_organization
      t.integer :benefit_type_id
      t.references :entrant_application, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
