class AddClerkToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :source, :string
    add_column :entrant_applications, :clerk, :string
  end
end
