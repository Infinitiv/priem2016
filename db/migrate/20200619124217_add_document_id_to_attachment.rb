class AddDocumentIdToAttachment < ActiveRecord::Migration
  def change
    add_column :attachments, :document_id, :integer
  end
end
