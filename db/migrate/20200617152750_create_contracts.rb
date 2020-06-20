class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.references :competitive_group, index: true, foreign_key: true
      t.references :attachment, index: true, foreign_key: true
      t.string :status

      t.timestamps null: false
    end
  end
end
