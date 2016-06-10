class CreateJoinTableCompetitiveGroupEntranceTestItem < ActiveRecord::Migration
  def change
    create_join_table :competitive_groups, :entrance_test_items do |t|
      # t.index [:competitive_grop_id, :entrance_test_item_id]
      # t.index [:entrance_test_item_id, :competitive_grop_id]
    end
  end
end
