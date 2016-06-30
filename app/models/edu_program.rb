class EduProgram < ActiveRecord::Base
  has_and_belongs_to_many :competitive_groups
  validates :name, :code, presence: true
end
