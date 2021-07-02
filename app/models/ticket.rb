class Ticket < ActiveRecord::Base
  belongs_to :entrant_application
  belongs_to :user
end
