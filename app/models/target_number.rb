class TargetNumber < ActiveRecord::Base
  belongs_to :target_organization
  belongs_to :competitive_group
end
