class AddAttachmentToEducationDocument < ActiveRecord::Migration
  def change
    add_reference :education_documents, :attachment, index: true, foreign_key: true
    add_column :education_documents, :status, :string
  end
end
