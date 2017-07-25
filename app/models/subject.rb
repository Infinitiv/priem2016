class Subject < ActiveRecord::Base
  has_many :marks
  has_many :entrance_test_items
  
  validates :subject_name, presence: true
end
