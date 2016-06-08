class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name, default: ""
      t.integer :year_start
      t.integer :year_end
      t.integer :status_id, default: 1
      t.integer :campaign_type_id

      t.timestamps
    end
  end
end
