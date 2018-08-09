class ReportsController < ApplicationController
  before_action :set_campaign
  def mon
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.select{|k, v| v[:summa] > 0}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit]]}.reverse
    @target_organizations = TargetOrganization.order(:target_organization_name)
  end
    
  private
  
  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
end
