class Api::StatsController < ApplicationController
  def entrants
    @entrants = Campaign.find_by_year_start(params[:id]).entrant_applications.select(:id, :registration_date).map(&:registration_date)
  end
  
  def campaigns
    @campaigns = Campaign.select(:id, :name, :year_start)
  end
end
