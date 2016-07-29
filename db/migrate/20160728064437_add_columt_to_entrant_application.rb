class AddColumtToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :enrolled, :integer
    add_column :entrant_applications, :enrolled_date, :date
    add_column :entrant_applications, :exeptioned, :integer
    add_column :entrant_applications, :exeptioned_date, :date
  end
end
