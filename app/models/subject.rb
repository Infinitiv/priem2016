class Subject < ActiveRecord::Base
  has_many :marks
  has_one :entrance_test_item
  
  validates :subject_id, :subject_name, presence: true
end
