class AddAttachmentToTargetContract < ActiveRecord::Migration
  def change
    add_reference :target_contracts, :attachment, index: true, foreign_key: true
    add_column :target_contracts, :status, :string
  end
end
