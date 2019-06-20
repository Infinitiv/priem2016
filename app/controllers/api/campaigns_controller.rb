class Api::CampaignsController < ApplicationController
  before_filter :set_campaign, only: [:show]
  def index
    @campaigns = Campaign.includes(:admission_volumes, :competitive_groups).where(status_id: 0)
  end
  
  def show
  end
  
  private
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
