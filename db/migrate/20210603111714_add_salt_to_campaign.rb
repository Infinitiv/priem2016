class AddSaltToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :salt, :string
  end
end
