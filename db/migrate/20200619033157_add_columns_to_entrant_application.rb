class AddColumnsToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :address, :text
    add_column :entrant_applications, :zip_code, :string
    add_column :entrant_applications, :phone, :string
    add_column :entrant_applications, :special_conditions, :text
    add_column :entrant_applications, :locked_by, :integer
  end
end
