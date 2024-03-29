class Request < ActiveRecord::Base
  require 'builder'
#   validates :query, :input, :output, :status, presence: true

def self.http_params
  case Rails.env
    when 'development'
      url = 'priem.edu.ru:8000'
      proxy_ip = nil
      proxy_port = nil
    when 'production' 
      url = '127.0.0.1:8080'
      proxy_ip = nil
      proxy_port = nil
  end
  uri = URI.parse('http://' + url + '/import/importservice.svc')
  return {uri_host: uri.host, uri_path: uri.path, uri_port: uri.port, proxy_ip: proxy_ip, proxy_port: proxy_port}
end
  
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
    when '/checkapplication/single'
      application = Application.select(:id, :application_number, :registration_date).find_by_number(params[:application_number])
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.CheckApp do |ca|
          ca.RegistrationDate application.registration_date.to_datetime.to_s.gsub('+00', '+03')
          ca.ApplicationNumber application.number
        end
      end  
    when '/institutioninfo'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
      end
    when '/validate'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.PackageData do |pd|
          campaign_info(pd, params) if params[:campaign_info]
	  admission_info(pd, params) if params[:admission_info]
          institution_achievements(pd, params) if params[:institution_achievements]
          target_organizations(pd, params) if params[:target_organizations]
	  applications(pd, params) if params[:applications]
          orders_of_admission(pd, params) if params[:orders_of_admission]
          institution_programs(pd, params) if params[:institution_programs]
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
          target_organizations(pd, params) if params[:target_organizations]
	  applications(pd, params) if params[:applications]
          orders_of_admission(pd, params) if params[:orders_of_admission]
          institution_programs(pd, params) if params[:institution_programs]
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
          c.Name [campaign.name, campaign.year_start].join(" ")
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
      if params[:admission_info_admission_volume]
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
              i.IsPlan false
            end
          end
        end
      end
      if params[:admission_info_distributed_admission_volume]
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
              i.IsPlan false
            end
          end
        end
      end
      if params[:admission_info_competitive_groups]
        competitive_groups = campaign.competitive_groups
        ai.CompetitiveGroups do |cgs|
          competitive_groups.each do |item|
            cgs.CompetitiveGroup do |cg|
              cg.UID item.id
              cg.CampaignUID item.campaign_id
              cg.Name [item.name, campaign.year_start].join(" ")
              cg.EducationLevelID item.education_level_id
              cg.EducationSourceID item.education_source_id
              cg.EducationFormID item.education_form_id
              cg.DirectionID item.direction_id
              edu_programs = item.edu_programs
              cg.EduPrograms do |eps|
                edu_programs.each do |sub_item|
                  eps.EduProgram do |ep|
                    ep.UID sub_item.id
                  end
                end
              end
              cg.IsForKrym true if item.is_for_krym
              cg.IsAdditional true if item.is_additional
              cg.LevelBudget 1
              competitive_group_item = item.competitive_group_item
              case item.education_source_id
              when 14
                cg.CompetitiveGroupItem do |cgi|
                  case item.education_form_id
                  when 11
                    cgi.NumberBudgetO competitive_group_item.number_budget_o || 0
                  when 12
                    cgi.NumberBudgetOZ competitive_group_item.number_budget_oz || 0
                  when 10
                    cgi.NumberBudgetZ competitive_group_item.number_budget_z || 0
                  end
                end
              when 15
                cg.CompetitiveGroupItem do |cgi|
                  case item.education_form_id
                  when 11
                    cgi.NumberPaidO competitive_group_item.number_paid_o || 0
                  when 12
                    cgi.NumberPaidOZ competitive_group_item.number_paid_oz || 0
                  when 10
                    cgi.NumBerPaidZ competitive_group_item.number_paid_z || 0
                  end
                end
              when 16
                target_numbers = item.target_numbers
                if target_numbers.empty?
                  cg.CompetitiveGroupItem do |cgi|
                    case item.education_form_id
                    when 11
                      cgi.NumberTargetO competitive_group_item.number_target_o || 0
                    when 12
                      cgi.NumberTargetOZ competitive_group_item.number_target_oz || 0
                    when 10
                      cgi.NumberTargetZ competitive_group_item.number_target_z || 0
                    end
                  end
                end
                unless target_numbers.empty?
                  cg.TargetOrganizations do |tos|
                    target_numbers.each do |sub_item|
                      tos.TargetOrganization do |to|
                        to.UID sub_item.target_organization_id
                        to.CompetitiveGroupTargetItem do |cgti|
                          case item.education_form_id
                          when 11
                            cgti.NumberTargetO sub_item.number_target_o || 0
                          when 12
                            cgti.NumberTargetOZ sub_item.number_target_oz || 0
                          when 10
                            cgti.NumberTargetZ sub_item.number_target_z || 0
                          end
                        end
                      end
                    end
                  end
                end
              when 20
                cg.CompetitiveGroupItem do |cgi|
                  case item.education_form_id
                  when 11
                    cgi.NumberQuotaO competitive_group_item.number_quota_o || 0
                  when 12
                    cgi.NumberQuotaOZ competitive_group_item.number_quota_oz || 0
                  when 10
                    cgi.NumberQuotaZ competitive_group_item.number_quota_z || 0
                  end
                end
              end
              entrance_test_items = item.entrance_test_items
              cg.EntranceTestItems do |etis|
                entrance_test_items.each do |sub_item|
                  etis.EntranceTestItem do |eti|
                    eti.UID "#{sub_item.id}-#{item.id}"
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
  
  def self.institution_achievements(pd, params)
    campaign = Campaign.find(params[:campaign_id])
    institution_achievements = campaign.institution_achievements
    pd.InstitutionAchievements do |ias|
      institution_achievements.each do |item|
        ias.InstitutionAchievement do |ia|
          ia.InstitutionAchievementUID item.id
          ia.Name item.name
          ia.IdCategory item.id_category
          ia.MaxValue item.max_value
          ia.CampaignUID item.campaign_id
        end
      end
    end
  end
  
  def self.target_organizations(pd, params)
    target_organizations_list = TargetOrganization.order(:target_organization_name)
    pd.TargetOrganizations do |tos|
      target_organizations_list.each do |item|
        tos.TargetOrganization do |to|
          to.UID item.id
          to.Name item.target_organization_name
        end
      end
    end
  end
  
  def self.institution_programs(pd, params)
    institution_programs_list = EduProgram.order(:code)
    pd.InstitutionPrograms do |ips|
      institution_programs_list.each do |item|
        ips.InstitutionProgram do |ip|
          ip.UID item.id
          ip.Name item.name
          ip.Code item.code
        end
      end
    end
  end
  
  def self.applications(pd, params)
    campaign = Campaign.find(params[:campaign_id])
    last_import_date = Request.select(:query, :output, :created_at).where(query: 'import').select{|r| Nokogiri::XML(r.output).at_css('PackageID')}.last.created_at
    applications = campaign.entrant_applications.includes(:identity_documents, :education_document, :marks, :competitive_groups, :subjects).where(status_id: [4, 6])
    applications = applications.where('updated_at > ?', last_import_date) unless params[:all_applications]
    
    pd.Applications do |as|
      applications.each do |item|
        original_received_date = item.education_document.original_received_date
        if item.competitive_groups.count > 0
          as.Application do |a|
            postfix = case true
                      when campaign.education_levels.include?(5)
                        's'
                      when campaign.education_levels.include?(18)
                        'o'
                      end
            application_number = [campaign.year_start, "%04d" % item.application_number, postfix].join('-')
            a.UID application_number
            a.ApplicationNumber application_number
            a.Entrant do |e|
              e.UID application_number
              e.LastName item.entrant_last_name
              e.FirstName item.entrant_first_name
              e.MiddleName item.entrant_middle_name if item.entrant_middle_name
              e.GenderID item.gender_id
              e.SNILS item.snils if item.snils
              e.EmailOrMailAddress do |eoma|
                eoma.Email item.email
              end
              unless item.competitive_groups.where(is_for_krym: true).empty?
                e.IsFromKrym do |efk|
                  efk.DocumentUID item.identity_documents.last.id 
                end
              end
            end
            a.RegistrationDate item.registration_date.to_datetime.to_s.gsub('+00', '+03')
            a.NeedHostel item.need_hostel
            a.StatusID params[:new_applications] ? 2 : item.status_id
            if item.status_id == 6
              a.ReturnDocumentsDate item.return_documents_date.to_datetime.to_s.gsub('+00', '+03')
              a.ReturnDocumentsTypeId 1
            end
            a.FinSourceAndEduForms do |fsaefs|
              item.competitive_groups.each do |sub_item|
                agreed_date = nil
                disagreed_date = item.exeptioned_date
                fsaefs.FinSourceEduForm do |fsef|
                  if sub_item.id == item.budget_agr || sub_item.id == item.paid_agr || sub_item.id == item.exeptioned
                    unless item.attachments.where(document_type: 'consent_application', template: false).order(:created_at).empty?
                      agreed_date = item.attachments.where(document_type: 'consent_application', template: false).order(:created_at).last.created_at.to_datetime.to_s
                      original_received_date ||= agreed_date
                    end
                  end
                  fsef.CompetitiveGroupUID sub_item.id
                  if agreed_date
                    fsef.IsAgreedDate agreed_date
                  end
                  if sub_item.education_source_id == 16
                    fsef.TargetOrganizationUID item.target_contracts.where(competitive_group_id: sub_item.id).first.target_organization_id
                  end
#                   if item.education_document.original_received_date
#                     fsef.IsAgreedDate item.registration_date.to_datetime.to_s.gsub('+00', '+03') if item.budget_agr == sub_item.id || item.paid_agr == sub_item.id
#                   end
                end
              end
            end
            benefit_competitive_groups = item.competitive_groups.where(education_source_id: 20)
#             olympic_documents = item.olympic_documents
            unless benefit_competitive_groups.empty? #|| olympic_documents.empty?
              a.ApplicationCommonBenefits do |acbs|
                benefit_competitive_groups.each do |sub_item|
                  acbs.ApplicationCommonBenefit do |acb|
                    acb.UID ["benefit", campaign.year_start, item.application_number, sub_item.id].join('-')
                    acb.CompetitiveGroupUID sub_item.id
                    benefit_document = item.benefit_documents.last
                    acb.DocumentTypeID benefit_document.benefit_document_type_id
                    acb.DocumentReason do |dr|
                      case benefit_document.benefit_document_type_id
                      when 11
                        dr.MedicalDocuments do |mds|
                          mds.BenefitDocument do |bd|
                            bd.DisabilityDocument do |dd|
                              dd.UID ["benefit", campaign.year_start, item.application_number, benefit_document.id].join('-')
                              dd.DocumentSeries benefit_document.benefit_document_series ? benefit_document.benefit_document_series : 'нет'
                              dd.DocumentNumber benefit_document.benefit_document_number if benefit_document.benefit_document_number
                              dd.DocumentDate benefit_document.benefit_document_date if benefit_document.benefit_document_date
                              dd.DocumentOrganization benefit_document.benefit_document_organization if benefit_document.benefit_document_organization
                              dd.DisabilityTypeID benefit_document.benefit_type_id
                            end
                          end
                          mds.AllowEducationDocument do |aed|
                            aed.UID ["allow", campaign.year_start, item.application_number, benefit_document.id].join('-')
                            aed.DocumentNumber "0000"
                            aed.DocumentDate benefit_document.benefit_document_date if benefit_document.benefit_document_date
                          end
                        end
                      when 30
                        dr.OrphanDocument do |od|
                          dr.UID ["benefit", campaign.year_start, item.application_number, benefit_document.id].join('-')
                          dr.OrphanCategoryID benefit_document.benefit_type_id
                          dr.DocumentName "Документ, подтверждающий сиротство"
                          dr.DocumentSeries benefit_document.benefit_document_series.nil? || benefit_document.benefit_document_series.empty?  ? 'нет' : benefit_document.benefit_document_series 
                          dr.DocumentNumber benefit_document.benefit_document_number if benefit_document.benefit_document_number
                          dr.DocumentDate benefit_document.benefit_document_date if benefit_document.benefit_document_date
                          dr.DocumentOrganization benefit_document.benefit_document_organization if benefit_document.benefit_document_organization
                        end
                      end
                    end
                    acb.BenefitKindID benefit_document.benefit_type_id
                  end
                end
#                 unless olympic_documents.empty?
#                   acbs.ApplicationCommonBenefit do |acb|
#                     acb.UID ["olympic", campaign.year_start, item.application_number].join('-')
#                     acb.CompetitiveGroupUID item.budget_agr
#                     olympic_document = olympic_documents.last
#                     acb.DocumentTypeID 9
#                     acb.DocumentReason do |dr|
#                       dr.OlympicDocument do |od|
#                         od.UID ["olympic", campaign.year_start, item.application_number, olympic_document.id].join('-')
#                         od.OriginalReceivedDate item.education_document.original_received_date if item.education_document.original_received_date
#                         od.DocumentSeries olympic_document.olympic_document_series if olympic_document.olympic_document_series
#                         od.DocumentNumber olympic_document.olympic_document_number if olympic_document.olympic_document_number
#                         od.DocumentDate olympic_document.olympic_document_date if olympic_document.olympic_document_date
#                         od.DiplomaTypeID olympic_document.diploma_type_id
#                         od.OlympicID olympic_document.olympic_id
#                         od.ProfileID olympic_document.olympic_profile_id
#                         od.ClassNumber  olympic_document.class_number
#                         od.OlympicSubjectID olympic_document.olympic_subject_id if olympic_document.olympic_subject_id
#                         od.EgeSubjectID olympic_document.ege_subject_id if olympic_document.ege_subject_id
#                       end
#                     end
#                     acb.BenefitKindID olympic_document.benefit_type_id
#                   end
#                 end
              end
            end
            a.ApplicationDocuments do |ads|
              identity_documents = item.identity_documents.order(identity_document_date: :asc)
              identity_document = identity_documents.last
              other_identity_documents = identity_documents - [identity_documents.last]
              ads.IdentityDocument do |id|
                id.UID ["id", campaign.year_start, identity_document.id].join('-')
                unless identity_document.identity_document_series.nil? || identity_document.identity_document_series.empty?
                  id.DocumentSeries identity_document.identity_document_series
                end
                id.DocumentNumber identity_document.identity_document_number
                id.DocumentDate identity_document.identity_document_date
                id.IdentityDocumentTypeID identity_document.identity_document_type
                if item.nationality_type_id == 1
                  id.ReleaseCountryID 1
                else
                  id.ReleaseCountryID item.nationality_type_id
                end
                id.ReleasePlace  identity_document.identity_document_issuer
                id.NationalityTypeID  item.nationality_type_id
                id.BirthDate item.birth_date
              end
              unless other_identity_documents.empty?
                ads.OtherIdentityDocuments do |oid|
                  other_identity_documents.each do |identity_document|
                    oid.IdentityDocument do |id|
                      id.UID ["id", campaign.year_start, identity_document.id].join('-')
                      id.LastName identity_document.alt_entrant_last_name ? identity_document.alt_entrant_last_name : item.entrant_last_name
                      id.FirstName identity_document.alt_entrant_first_name ? identity_document.alt_entrant_first_name : item.entrant_first_name
                      id.MiddleName (identity_document.alt_entrant_middle_name ? identity_document.alt_entrant_middle_name : item.entrant_middle_name) if item.entrant_middle_name
                      unless identity_document.identity_document_series.nil? || identity_document.identity_document_series.empty? 
                        id.DocumentSeries identity_document.identity_document_series
                      end
                      id.DocumentNumber identity_document.identity_document_number
                      oid.DocumentDate identity_document.identity_document_date ? identity_document.identity_document_date : item.birth_date + 14.day
                      id.IdentityDocumentTypeID identity_document.identity_document_type
                      id.NationalityTypeID  item.nationality_type_id
                      id.BirthDate item.birth_date
                    end
                  end
                end
              end
              ads.EduDocuments do |eds|
                edu_document = item.education_document
                eds.EduDocument do |ed|
                  case edu_document.education_document_type
                  when "SchoolCertificateDocument"
                    ed.SchoolCertificateDocument do |scd|
                      scd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                      if original_received_date
                        scd.OriginalReceivedDate original_received_date.to_date
                      end
                      if edu_document.education_document_date.year > 2013
                        scd.DocumentNumber edu_document.education_document_number
                      else
                        scd.DocumentSeries edu_document.education_document_number.first(4)
                        scd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 4)
                      end
                      scd.DocumentDate edu_document.education_document_date
                      scd.DocumentOrganization edu_document.education_document_issuer ? edu_document.education_document_issuer : 'школа'
                    end
                  when "MiddleEduDiplomaDocument"
                    ed.MiddleEduDiplomaDocument do |medd|
                      medd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                      if original_received_date
                        medd.OriginalReceivedDate original_received_date.to_date
                      end
                      if edu_document.education_document_date.year > 2013
                        medd.DocumentSeries edu_document.education_document_number.first(6)
                        medd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 6)
                      else
                        medd.DocumentSeries edu_document.education_document_number.first(5)
                        medd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 5)
                      end
                      medd.DocumentDate edu_document.education_document_date
                      medd.DocumentOrganization  edu_document.education_document_issuer ? edu_document.education_document_issuer : 'колледж'
                    end
                  when "HighEduDiplomaDocument"
                    ed.HighEduDiplomaDocument do |hedd|
                      hedd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                      if original_received_date
                        hedd.OriginalReceivedDate original_received_date.to_date
                      end
                      hedd.DocumentSeries edu_document.education_document_number.first(3)
                      hedd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 3)
                      hedd.DocumentDate edu_document.education_document_date
                      hedd.DocumentOrganization  edu_document.education_document_issuer ? edu_document.education_document_issuer : 'вуз'
                    end
                  end
                end
              end
              achievements = item.achievements
              unless achievements.empty? || achievements.sum(:value) == 0
                ads.CustomDocuments do |cds|
                  n = 0
                  achievements.each do |sub_item|
                    if sub_item.value > 0
                      n += 1
                      cds.CustomDocument do |cd|
                        case sub_item.institution_achievement.id_category
                        when 8
                          cd.UID ["ach", campaign.year_start, item.application_number, postfix, 'gto'].join('-')
                          cd.DocumentName "Удоствоверение о награждении золотым значком ГТО"
                          cd.DocumentDate "#{campaign.year_start}-04-20"
                          cd.DocumentOrganization 'Министерство спорта Российской Федерации'
                        when 9
                          cd.UID ["ach", campaign.year_start, item.education_document.id].join('-')
                          cd.DocumentName "Аттестат о среднем общем образовании с отличием"
                          cd.DocumentDate item.education_document.education_document_date
                          cd.DocumentOrganization item.education_document.education_document_issuer ? item.education_document.education_document_issuer : "Организация СО"
                        when 15
                          cd.UID ["ach", campaign.year_start, item.education_document.id].join('-')
                          cd.DocumentName "Аттестат о среднем (полном) общем образовании для награжденных золотой медалью"
                          cd.DocumentDate item.education_document.education_document_date
                          cd.DocumentOrganization item.education_document.education_document_issuer ? item.education_document.education_document_issuer : "Организация СО"
                        when 16
                          cd.UID ["ach", campaign.year_start, item.education_document.id].join('-')
                          cd.DocumentName "Аттестат о среднем (полном) общем образовании для награжденных золотой медалью"
                          cd.DocumentDate item.education_document.education_document_date
                          cd.DocumentOrganization item.education_document.education_document_issuer ? item.education_document.education_document_issuer : "Организация СО"
                        when 17
                          cd.UID ["ach", campaign.year_start, item.education_document.id].join('-')
                          cd.DocumentName "Диплом о среднем профессиональном образовании с отличием"
                          cd.DocumentDate item.education_document.education_document_date
                          cd.DocumentOrganization item.education_document.education_document_issuer ? item.education_document.education_document_issuer : "Организация СПО"
                        else
                          cd.UID ["ach", campaign.year_start, item.application_number, postfix, 'other', n].join('-')
                          cd.DocumentName "Иной документ, подтверждающий индивидуальное достижение"
                          cd.DocumentDate item.registration_date.to_s
                          cd.DocumentOrganization 'Организация'
                        end
                      end
                    end
                  end
                end
              end
            end
            a.EntranceTestResults do |etrs|
              item.marks.each do |sub_item|
                item.competitive_groups.each do |cg|
                  etrs.EntranceTestResult do |etr|
                    etr.UID "#{sub_item.id}-#{cg.id}"
                    etr.ResultValue sub_item.value
                    case true
                    when sub_item.form == "ЕГЭ"
                      etr.ResultSourceTypeID 1
                    when sub_item.form == "ВИ"
                      etr.ResultSourceTypeID 2
                    when sub_item.form == "Аккредитация"
                      etr.ResultSourceTypeID 2
                    else
                      etr.ResultSourceTypeID 3
                    end
                    etr.EntranceTestSubject do |ets|
                      ets.SubjectID sub_item.subject.subject_id
  #                     ets.SubjectName sub_item.subject.subject_name
                    end
                    etr.EntranceTestTypeID sub_item.subject.entrance_test_item.entrance_test_type_id
                    etr.CompetitiveGroupUID cg.id
                    unless sub_item.form == "ЕГЭ"
                      etr.ResultDocument do |rd|
                        rd.InstitutionDocument do |id|
                          case sub_item.subject.subject_id
                          when 11
                            id.DocumentNumber "#{campaign.year_start}-1"
                            id.DocumentDate "#{campaign.year_start}-07-16"
                          when 4
                            id.DocumentNumber "#{campaign.year_start}-2"
                            id.DocumentDate "#{campaign.year_start}-07-19"
                          when 1
                            id.DocumentNumber "#{campaign.year_start}-3"
                            id.DocumentDate "#{campaign.year_start}-07-21"
                          else
                            id.DocumentNumber "#{campaign.year_start}-1"
                            id.DocumentDate "#{campaign.year_start}-08-06"
                          end
                          id.DocumentTypeID 1
                        end
                      end
                    end
                  end
                end
              end
            end
            achievements = item.achievements.includes(:institution_achievement)
            unless achievements.empty? || achievements.sum(:value) == 0
              a.IndividualAchievements do |ias|
                n = 0
                achievements.each do |sub_item|
                  if sub_item.value > 0
                    n += 1
                    ias.IndividualAchievement do |ia|
                      ia.IAUID [campaign.year_start, "%04d" % item.application_number, postfix, sub_item.institution_achievement.id_category, n].join('-')
                      ia.InstitutionAchievementUID sub_item.institution_achievement_id
                      ia.IAMark sub_item.value
                      case sub_item.institution_achievement.id_category
                      when 8
                        ia.IADocumentUID ["ach", campaign.year_start, item.application_number, postfix, 'gto'].join('-')
                      when 11
                        ia.IADocumentUID ["ach", campaign.year_start, item.application_number, postfix, 'other', n].join('-')
                      when 13
                        ia.IADocumentUID ["ach", campaign.year_start, item.application_number, postfix, 'other', n].join('-')
                      else
                        ia.IADocumentUID ["ach", campaign.year_start, item.education_document.id].join('-')
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
  end

  def self.orders_of_admission(pd, params)
    campaign = Campaign.find(params[:campaign_id])
    competitive_groups = campaign.competitive_groups
    pd.Orders do |os|
      os.OrdersOfAdmission do |ooas|
        competitive_groups.each do |competitive_group|
          competitive_group_enrolled_application = competitive_group.entrant_applications.where(enrolled: competitive_group.id).group_by(&:enrolled_date)
          unless competitive_group_enrolled_application.empty?
            competitive_group_enrolled_application.each do |d, a|
              ooas.OrderOfAdmission do |ooa|
                ooa.OrderOfAdmissionUID "oa #{campaign.year_start}-#{competitive_group.id}-#{d.to_date}"
                ooa.CampaignUID campaign.id
                ooa.OrderName "Admission order #{competitive_group.name} от #{d.to_date}"
                ooa.OrderDate d.to_date
                ooa.EducationFormID competitive_group.education_form_id
                ooa.FinanceSourceID competitive_group.education_source_id
                ooa.EducationLevelID competitive_group.education_level_id
                unless competitive_group.education_source_id == 15
                  if campaign.education_levels.include?(5)
                    case d.to_date.to_s
                    when "2021-08-17"
                      ooa.Stage 1
#                     when "2020-08-26"
#                       ooa.Stage 2
                    else
                      ooa.Stage 0
                    end
                  else
                    case d.to_date.to_s
                    when "2021-08-13"
                      ooa.Stage 1
#                     when "2021-08-13"
#                       ooa.Stage 2
                    else
                      ooa.Stage 0
                    end
                  end
                end
              end
            end
          end
        end
      end
      if campaign.entrant_applications.where.not(exeptioned: nil).count > 0
        os.OrdersOfException do |ooes|
          competitive_groups.each do |competitive_group|
            competitive_group_exeptioned_application = competitive_group.entrant_applications.where(exeptioned: competitive_group.id).group_by(&:exeptioned_date)
            unless competitive_group_exeptioned_application.empty?
              competitive_group_exeptioned_application.each do |d, a|
                ooes.OrderOfException do |ooa|
                  ooa.OrderOfExceptionUID "oe #{campaign.year_start}-#{competitive_group.id}-#{d.to_date}"
                  ooa.CampaignUID campaign.id
                  ooa.OrderName "Exeption order #{competitive_group.name} от #{d.to_date}"
                  ooa.OrderDate d.to_date
                  ooa.EducationFormID competitive_group.education_form_id
                  ooa.FinanceSourceID competitive_group.education_source_id
                  ooa.EducationLevelID competitive_group.education_level_id
                  unless competitive_group.education_source_id == 15
                    case d.to_date.to_s
                    when "2021-08-24"
                      ooa.Stage 1
#                     when "2021-08-26"
#                       ooa.Stage 2
                    else
                      ooa.Stage 0
                    end
                  end
                end
              end
            end
          end
        end
      end
      os.Applications do |as|
        competitive_groups.each do |competitive_group|
          competitive_group_enrolled_application = competitive_group.entrant_applications.where(enrolled: competitive_group.id).group_by(&:enrolled_date)
          unless competitive_group_enrolled_application.empty?
            competitive_group_enrolled_application.each do |d, a|
              a.each do |application|
                postfix = case true
                          when campaign.education_levels.include?(5)
                            's'
                          when campaign.education_levels.include?(18)
                            'o'
                          end
                application_number = [campaign.year_start, "%04d" % application.application_number, postfix].join('-')
                as.Application do |a|
                  a.ApplicationUID application_number
                  a.OrderUID "oa #{campaign.year_start}-#{competitive_group.id}-#{d.to_date}"
                  a.OrderTypeID 1
                  a.CompetitiveGroupUID competitive_group.id
                  a.OrderIdLevelBudget 1
                end
              end
            end
          end
        end
        competitive_groups.each do |competitive_group|
          competitive_group_exeptioned_application = competitive_group.entrant_applications.where(exeptioned: competitive_group.id).group_by(&:exeptioned_date)
          unless competitive_group_exeptioned_application.empty?
            competitive_group_exeptioned_application.each do |d, a|
              a.each do |application|
                postfix = case true
                          when campaign.education_levels.include?(5)
                            's'
                          when campaign.education_levels.include?(18)
                            'o'
                          end
                application_number = [campaign.year_start, "%04d" % application.application_number, postfix].join('-')
                as.Application do |a|
                  a.ApplicationUID application_number
                  a.OrderUID "oe #{campaign.year_start}-#{competitive_group.id}-#{d.to_date}"
                  a.OrderTypeID 2
                  a.CompetitiveGroupUID competitive_group.id
                  a.OrderIdLevelBudget 1
                  a.IsDisagreedDate d.to_datetime
                end
              end
            end
          end
        end
      end
    end
  end
  
  def self.applications_del(pd, params)
    campaign = Campaign.find(params[:campaign_id])
    applications = campaign.entrant_applications.includes(:identity_documents, :education_document, :marks, :competitive_groups, :subjects).where(status_id: [4, 6])
    postfix = case true
              when campaign.education_levels.include?(5)
                's'
              when campaign.education_levels.include?(18)
                'o'
              end
    
    pd.Applications do |as|
      applications.each do |item|
        as.Application do |a|
          a.ApplicationNumber [campaign.year_start, "%04d" % item.application_number, postfix].join('-')
          a.RegistrationDate item.registration_date.to_datetime.to_s.gsub('+00', '+03')
        end
      end
    end
  end
  
end
