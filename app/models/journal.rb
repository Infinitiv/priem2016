class Journal < ActiveRecord::Base
  belongs_to :user
  belongs_to :entrant_application
end
