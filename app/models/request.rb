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
    campaign = Campaign.find(params[:campaign_id])
    pd.AdmissionInfo do |ai|
      admission_volumes = campaign.admission_volumes
      ai.AdmissionVolume do |av|
        admission_volumes.each do |item|
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
      distributed_admission_volumes = campaign.distributed_admission_volumes
      ai.DistributedAdmissionVolume do |dav|
        distributed_admission_volumes.each do |item|
          dav.Item do |i|
            i.AdmissionVolumeUID item.admission_volume_id
            i.LevelBudget item.level_budget_id
            i.NumberBudgetO item.number_budget_o if item.number_budget_o > 0
            i.NumberBudgetOZ item.number_budget_oz if item.number_budget_oz > 0
            i.NumberBudgetZ item.number_budget_z if item.number_budget_z > 0
            i.NumberTargetO item.number_target_o if item.number_target_o > 0
            i.NumberTargetOZ item.number_target_oz if item.number_target_oz > 0
            i.NumberTargetZ item.number_target_z if item.number_target_z > 0
            i.NumberQuotaO item.number_quota_o if item.number_quota_o > 0
            i.NumberQuotaOZ item.number_quota_oz if item.number_quota_oz > 0
            i.NumberQuotaZ item.number_quota_z if item.number_quota_z > 0
          end
        end
      end
      competitive_groups = campaign.competitive_groups
      ai.CompetitiveGroups do |cgs|
        competitive_groups.each do |item|
          cgs.CompetitiveGroup do |cg|
            cg.UID item.id
            cg.CampaignUID item.campaign_id
            cg.Name item.name
            cg.EducationLevelID item.education_level_id
            cg.EducationSourceID item.education_source_id
            cg.EducationFormID item.education_form_id
            cg.DirectionID item.direction_id
            edu_programs = item.edu_programs
            cg.EduPrograms do |eps|
              edu_programs.each do |sub_item|
                eps.EduProgram do |ep|
                  ep.UID sub_item.id
                  ep.Name sub_item.name
                  ep.Code sub_item.code
                end
              end
            end
            cg.IsForKrym true if item.is_for_krym
            cg.IsAdditional true if item.is_additional
            competitive_group_item = item.competitive_group_item
            cg.CompetitiveGroupItem do |cgi|
              cgi.NumberBudgetO competitive_group_item.number_budget_o if competitive_group_item.number_budget_o > 0
              cgi.NumberBudgetOZ competitive_group_item.number_budget_oz if competitive_group_item.number_budget_oz > 0
              cgi.NumberBudgetZ competitive_group_item.number_budget_z if competitive_group_item.number_budget_z > 0
              cgi.NumberPaidO competitive_group_item.number_paid_o if competitive_group_item.number_paid_o > 0
              cgi.NumberPaidOZ competitive_group_item.number_paid_oz if competitive_group_item.number_paid_oz > 0
              cgi.NumberPaidZ competitive_group_item.number_paid_z if competitive_group_item.number_paid_z > 0
              cgi.NumberTargetO competitive_group_item.number_target_o if competitive_group_item.number_target_o > 0
              cgi.NumberTargetOZ competitive_group_item.number_target_oz if competitive_group_item.number_target_oz > 0
              cgi.NumberTargetZ competitive_group_item.number_target_z if competitive_group_item.number_target_z > 0
              cgi.NumberQuotaO competitive_group_item.number_quota_o if competitive_group_item.number_quota_o > 0
              cgi.NumberQuotaOZ competitive_group_item.number_quota_oz if competitive_group_item.number_quota_oz > 0
              cgi.NumberQuotaZ competitive_group_item.number_quota_z if competitive_group_item.number_quota_z > 0
            end
            target_numbers = item.target_numbers
            unless target_numbers.empty?
              cg.TargetOrganizations do |tos|
                target_numbers.each do |sub_item|
                  tos.TargetOrganization do |to|
                    to.UID sub_item.target_organization_id
                    to.CompetitiveGroupTargetItem do |cgti|
                      cgti.NumberTargetO sub_item.number_target_o if sub_item.number_target_o > 0
                      cgti.NumberTargetOZ sub_item.number_target_oz if sub_item.number_target_oz > 0
                      cgti.NumberTargetZ sub_item.number_target_z if sub_item.number_target_z > 0
                    end
                  end
                end
              end
            end
            entrance_test_items = item.entrance_test_items
            cg.EntranceTestItems do |etis|
              entrance_test_items.each do |sub_item|
                etis.EntranceTestItem do |eti|
                  eti.UID sub_item.id
                  eti.EntranceTestTypeID sub_item.entrance_test_type_id
                  eti.MinScore sub_item.min_score
                  eti.EntranceTestPriority sub_item.entrance_test_priority
                  subject = sub_item.subject
                  eti.EntranceTestSubject do |ets|
                    ets.SubjectID subject.subject_id
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
