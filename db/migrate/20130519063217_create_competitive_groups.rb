class CreateCompetitiveGroups < ActiveRecord::Migration
  def change
    create_table :competitive_groups do |t|
      t.references :campaign
      t.string :name, default: ""
      t.integer :education_level_id
      t.integer :education_source_id
      t.integer :education_form_id
      t.integer :direction_id
      t.boolean :is_for_krym, default: false
      t.boolean :is_additional, default: false
      
      t.timestamps
    end
    add_index :competitive_groups, :campaign_id
  end
end
