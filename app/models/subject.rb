class Subject < ActiveRecord::Base
  validates :subject_id, :subject_name, presence: true
end
