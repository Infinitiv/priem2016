class Api::StatsController < ApplicationController
  before_filter :set_campaign, only: [:entrants, :competitive_groups, :registration_dates]
  before_filter :set_entrant_applications, only: [:entrants]

  def show
  end
  def entrants
    @entrants = @entrant_applications.select(
      :application_number,
      :campaign_id,
      :gender_id,
      :birth_date,
      :region_id,
      :registration_date,
      :status_id,
      :nationality_type_id,
      :region_with_type,
      :enrolled,
      :enrolled_date,
      :exeptioned,
      :exeptioned_date,
      :return_documents_date,
      :source,
      :budget_agr,
      :snils
    )
    .includes(
      :competitive_groups,
      :marks,
      :benefit_documents,
      :education_document,
      :identity_documents,
      :achievements,
      :olympic_documents,
      :target_contracts,
      :target_organizations
    ).where(status_id: [4, 6])
    @specialities = Dictionary.find_by_code(10).items
    @countries = Dictionary.find_by_code(7).items
  end

  def registration_dates
    registration_dates = @campaign.entrant_applications.select(:id, :status_id, :registration_date).where(status_id: [4, 6]).map(&:registration_date)
    send_data registration_dates.to_json, type: 'text/json', disposition: 'inline'
  end

  def campaigns
    @campaigns = Campaign.select(:id, :name, :year_start, :campaign_type_id).where(campaign_type_id: 1)
  end
  
  private
  
  def competitive_groups
    @competitive_groups = CompetitiveGroup.select(
      :id,
      :campaign_id,
      :name,
      :education_source_id,
      :direction_id,
      :last_admission_date
      )
    .includes(:competitive_group_item)
    .joins(:campaign)
    .where(campaigns: {id: @campaign})
  end
  
  
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
  
  def set_entrant_applications
    @entrant_applications = @campaign.entrant_applications.includes(:marks, :target_contracts, :education_document).select(:id, :registration_date, :region_id, :enrolled).where(status_id: [4, 6])
  end
end
