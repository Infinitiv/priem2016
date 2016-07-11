class Subject < ActiveRecord::Base
  has_many :marks
  
  validates :subject_id, :subject_name, presence: true
end
