class AddAttachmentToBenefitDocument < ActiveRecord::Migration
  def change
    add_reference :benefit_documents, :attachment, index: true, foreign_key: true
    add_column :benefit_documents, :status, :string
  end
end
