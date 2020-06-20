class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.string :document_type
      t.string :mime_type
      t.string :data_hash
      t.string :status
      t.boolean :merged
      t.boolean :template

      t.timestamps null: false
    end
  end
end
