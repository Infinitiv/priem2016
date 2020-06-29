class AddRequestToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :request, :text
  end
end
