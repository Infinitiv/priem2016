class TargetOrganization < ActiveRecord::Base
  has_many :target_contracts
  has_many :entrant_applications, through: :target_contracts
  validates :target_organization_name, presence: true
end
