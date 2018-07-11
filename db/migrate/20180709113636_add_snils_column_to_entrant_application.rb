class AddSnilsColumnToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :snils, :string, default: ''
  end
end
