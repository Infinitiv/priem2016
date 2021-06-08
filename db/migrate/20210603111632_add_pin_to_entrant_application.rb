class AddPinToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :pin, :integer
  end
end
