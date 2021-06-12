class AddSnilsAbsentToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :snils_absent, :boolean, default: false
  end
end
