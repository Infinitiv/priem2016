class CreateOlympicDocuments < ActiveRecord::Migration
  def change
    create_table :olympic_documents do |t|
      t.integer :benefit_type_id
      t.references :entrant_application, index: true, foreign_key: true
      t.integer :olympic_id
      t.integer :diploma_type_id
      t.integer :olympic_profile_id
      t.integer :class_number
      t.string :olympic_document_series
      t.string :olympic_document_number
      t.date :olympic_document_date
      t.integer :olympic_subject_id
      t.integer :ege_subject_id

      t.timestamps null: false
    end
  end
end
