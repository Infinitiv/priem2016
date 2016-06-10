class TargetOrganization < ActiveRecord::Base
  validates :target_organization_name, presence: true
end