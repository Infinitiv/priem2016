class AddAttachmentToOlympicDocument < ActiveRecord::Migration
  def change
    add_reference :olympic_documents, :attachment, index: true, foreign_key: true
    add_column :olympic_documents, :status, :string
  end
end
