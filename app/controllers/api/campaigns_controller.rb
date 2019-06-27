class Api::CampaignsController < ApplicationController
  before_filter :set_campaign, only: [:show]
  def index
    @campaigns = Campaign.includes(:admission_volumes, :competitive_groups, :institution_achievements).where(status_id: 1)
  end
  
  def show
  end
  
  private
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
