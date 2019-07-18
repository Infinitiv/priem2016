class CreateTargetContracts < ActiveRecord::Migration
  def change
    create_table :target_contracts do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.references :competitive_group, index: true, foreign_key: true
      t.references :target_organization, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
