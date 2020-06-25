class AddStatusToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :status, :string
  end
end
