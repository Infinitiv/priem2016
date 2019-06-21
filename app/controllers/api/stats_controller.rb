class Api::StatsController < ApplicationController
  before_filter :set_campaign, only: [:entrants, :marks]
  def entrants
    @entrants = @campaign.entrant_applications.select(:id, :registration_date).map(&:registration_date)
  end
  
  def campaigns
    @campaigns = Campaign.where("5 = any(education_levels)").select(:id, :name, :year_start)
  end
  
  def marks
    level = case @campaign.year_start
            when 2016
              38
            when 2017
              42
            when 2018
              42
            when 2019
              42
            end
    @marks = Mark.select(:id, 
                         :value, 
                         :entrant_application_id, 
                         :form, 
                         :subject_id).includes(:subject).joins(:entrant_application).where(entrant_applications: {
                                                                                                                  campaign_id: @campaign
                                                                                                                 }, 
                                                                                           form: 'ЕГЭ').where("value >= ?", level).map{|m| [m.subject.subject_name, m.value]}
  end
  
  private
  
  def set_campaign
    @campaign = Campaign.where("5 = any(education_levels)").find_by_year_start(params[:id])
  end
end
