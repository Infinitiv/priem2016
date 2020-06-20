class AddCommentToEntrantApplication < ActiveRecord::Migration
  def change
    add_column :entrant_applications, :comment, :text
    add_reference :entrant_applications, :attachment, index: true, foreign_key: true
  end
end
