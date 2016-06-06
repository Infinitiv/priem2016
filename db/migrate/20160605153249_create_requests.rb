class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :query
      t.text :input
      t.text :output
      t.string :status

      t.timestamps null: false
    end
  end
end
