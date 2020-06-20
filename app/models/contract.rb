class Contract < ActiveRecord::Base
  belongs_to :entrant_application
  belongs_to :competitive_group
  belongs_to :attachment
end
