class AddYearToMark < ActiveRecord::Migration
  def change
    add_column :marks, :year, :string
  end
end
