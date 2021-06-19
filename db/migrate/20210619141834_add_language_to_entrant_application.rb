class AddLanguageToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :language, :string, default: ''
  end
end
