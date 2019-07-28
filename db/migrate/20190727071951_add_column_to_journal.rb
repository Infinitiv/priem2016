class AddColumnToJournal < ActiveRecord::Migration
  def change
    add_column :journals, :done, :boolean, default: false
  end
end
