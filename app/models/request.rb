class Request < ActiveRecord::Base
  require 'builder'
#   validates :query, :input, :output, :status, presence: true
  
  def self.data(method, params)
    case method
    when '/dictionary'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
      end
    when '/dictionarydetails'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.GetDictionaryContent do |gdc|
          gdc.DictionaryCode params[:dictionary_number]
        end
      end
    when '/checkapplication'
      application = Application.select(:id, :number, :registration_date).find_by_number(params[:application_number])
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.CheckApp do |ca|
          ca.RegistrationDate application.registration_date
          ca.ApplicationNumber application.number
        end
      end  
    when '/institutioninfo'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
      end
    when '/validate' || '/import'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.PackageData do |pd|
          campaign_info(pd, params) if params[:campaign_info]
	  admission_info(pd, params) if params[:admission_info]
          institution_achievements(pd, params) if params[:institution_achievements]
	  applications(pd, params) if params[:applications]
          orders_of_admission(pd, params) if params[:orders_of_admission]
        end
      end
    when '/import'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.PackageData do |pd|
          campaign_info(pd, params) if params[:campaign_info]
	  admission_info(pd, params) if params[:admission_info]
          institution_achievements(pd, params) if params[:institution_achievements]
	  applications(pd, params) if params[:applications]
          orders_of_admission(pd, params) if params[:orders_of_admission]
        end
      end
    when '/delete'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.DataForDelete do |pd|
	  applications_del(pd, params) if params[:applications]
        end
      end
    end
  end
  
  def self.auth_data(root)
    auth_data = ::Builder::XmlMarkup.new(indent: 2)
    root.AuthData do |ad|
      ad.Login ENV['LOGIN']
      ad.Pass ENV['PASSWORD']
    end
  end
  
  def self.campaign_info(pd, params)
    pd.CampaignInfo do |ci|
      ci.Campaigns do |cs|
        cs.Campaign do |c|
          campaign = Campaign.find params[:campaign_id]
          c.UID campaign.id
          c.Name campaign.name
          c.YearStart campaign.year_start
          c.YearEnd campaign.year_end
          c.EducationForms do |edfs|
            campaign.education_forms.each do |ef|
              edfs.EducationFormID ef
            end
          end
          c.StatusID campaign.status_id
          c.EducationLevels do |edls|
            campaign.education_levels.each do |el|
              edls.EducationLevelID el
            end
          end
          c.CampaignTypeID campaign.campaign_type_id
        end
      end
    end
  end
  
  def self.admission_info(pd, params)
    pd.AdmissionInfo do |ai|
      ai.AdmissionVolume do |av|
        items = AdmissionVolume.where(campaign_id: params[:campaign_id])
        items.each do |item|
          av.Item do |i|
            i.UID item.id
            i.CampaignUID item.campaign.id
            i.EducationLevelID item.education_level_id
            i.DirectionID item.direction_id
            i.NumberBudgetO item.number_budget_o if item.number_budget_o > 0
            i.NumberBudgetOZ item.number_budget_oz if item.number_budget_oz > 0
            i.NumberBudgetZ item.number_budget_z if item.number_budget_z > 0
            i.NumberPaidO item.number_paid_o if item.number_paid_o > 0
            i.NumberPaidOZ item.number_paid_oz if item.number_paid_oz > 0
            i.NumberPaidZ item.number_paid_z if item.number_paid_z > 0
            i.NumberTargetO item.number_target_o if item.number_target_o > 0
            i.NumberTargetOZ item.number_target_oz if item.number_target_oz > 0
            i.NumberTargetZ item.number_target_z if item.number_target_z > 0
            i.NumberQuotaO item.number_quota_o if item.number_quota_o > 0
            i.NumberQuotaOZ item.number_quota_oz if item.number_quota_oz > 0
            i.NumberQuotaZ item.number_quota_z if item.number_quota_z > 0
          end
        end
      end
    end
  end
end
