class AddReturnDocumentsDateColumnToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :return_documents_date, :date
  end
end
