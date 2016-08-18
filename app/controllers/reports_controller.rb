class ReportsController < ApplicationController
  before_action :set_campaign
  def mon
    admission_volumes = @campaign.admission_volumes
    @report = Report.mon(admission_volumes)
  end
    
  private
  
  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
end