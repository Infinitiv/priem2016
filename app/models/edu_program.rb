class EduProgram < ActiveRecord::Base
  validates :name, :code, presence: true
end
