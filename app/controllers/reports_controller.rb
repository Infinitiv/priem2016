class ReportsController < ApplicationController
  load_and_authorize_resource
  before_action :set_campaign
  def mon
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
    @target_organizations = TargetOrganization.order(:target_organization_name)
  end
    
  private
  
  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
end
