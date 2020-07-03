class AddNameToOtherDocument < ActiveRecord::Migration
  def change
    add_column :other_documents, :name, :string
  end
end
