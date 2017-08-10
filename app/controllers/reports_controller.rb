class ReportsController < ApplicationController
  before_action :set_campaign
  def mon
    @report = Report.mon(@campaign)
  end
    
  private
  
  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
end
