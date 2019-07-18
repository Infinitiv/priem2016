class TargetContract < ActiveRecord::Base
  belongs_to :entrant_application
  belongs_to :competitive_group
  belongs_to :target_organization
end
