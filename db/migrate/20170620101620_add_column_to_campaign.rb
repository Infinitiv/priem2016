class AddColumnToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :google_key_development, :string
    add_column :campaigns, :google_key_production, :string
  end
end
