class AddAnotherColumnToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :contracts, :integer, array: true
  end
end
