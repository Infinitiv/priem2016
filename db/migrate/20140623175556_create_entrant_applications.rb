class CreateEntrantApplications < ActiveRecord::Migration
  def change
    create_table :entrant_applications do |t|
      t.integer :registration_number
      t.integer :application_number
      t.integer :campaign_id
      t.string :entrant_last_name
      t.string :entrant_first_name
      t.string :entrant_middle_name
      t.integer :gender_id
      t.date :birth_date
      t.integer :region_id
      t.string :email
      t.date :registration_date
      t.boolean :need_hostel, :default => false
      t.integer :status_id, :default => 2
      t.integer :nationality_type_id
      t.integer :target_organization_id
      t.boolean :special_entrant, default: false
      t.boolean :olympionic, default: false
      t.boolean :benefit, default: false
      t.string :data_hash
      t.boolean :checked, default: false

      t.timestamps
    end
  end
end
