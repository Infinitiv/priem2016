class Api::CampaignsController < ApplicationController
  before_filter :set_campaign, only: [:show]
  def index
    @campaigns = Campaign.includes(:admission_volumes, :institution_achievements, :entrance_test_items, :subjects, :competitive_groups, :competitive_group_items).where(status_id: 1)
  end
  
  def show
  end
  
  private
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
