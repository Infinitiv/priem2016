class AddColumnToOlympicDocument < ActiveRecord::Migration
  def change
    add_column :olympic_documents, :olympic_document_type_id, :integer
  end
end
