namespace :priem do
  require 'builder'
  desc "Publish competition lists to google drive"
  task competition_lists: :environment do
    
    campaign = Campaign.first
    admission_volume_hash = EntrantApplication.admission_volume_hash(campaign)
    applications_hash = EntrantApplication.applications_hash(campaign)
    target_organizations = TargetOrganization.order(:target_organization_name)
    all_competitive_groups = CompetitiveGroup.all

    session = GoogleDrive.saved_session("config/google_drive.json")
    case Rails.env
      when 'development'
        s = session.spreadsheet_by_key("1YTVWLPoB8-ADiyOKNiwyo94R_B33WghIGZ0h8-IHuqw")
        s.title = "Конкурсные списки (тестовые) по состоянию на #{Time.now.to_datetime.strftime("%F %T")}"
      when 'production'
        s = session.spreadsheet_by_key("1BFjqg-cdIHAfZit78v8Y_tk8sDBHOfckghZVKkjnX2E")        
        s.title = "Конкурсные списки по состоянию на #{Time.now.to_datetime.strftime("%F %T")}"
    end
    
    admission_volume_hash.each do |direction_id, competitive_groups|
      competitive_groups.select{|k, v| k.is_for_krym == false && [15].include?(k.education_source_id) }.each do |competitive_group, numbers|
        ws = s.worksheet_by_title(competitive_group.name) ? s.worksheet_by_title(competitive_group.name) : s.add_worksheet(competitive_group.name)
        if competitive_group.education_source_id == 16
          r = 1
          if ws.max_rows > 3
            ws.delete_rows(3, ws.max_rows - 2)
            ws.save
          end
          target_organizations.each do |target_organization|
          applications = applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.target_organization_id == target_organization.id}
            unless applications.empty?
              ws[r, 1]= target_organization.target_organization_name
              ws[r + 1, 1] = "№№"
              ws[r + 1, 2] = "№ личного дела"
              ws[r + 1, 3] = "Ф.И.О."
              ws[r + 1, 4] = "Химия"
              ws[r + 1, 5] = "Биология"
              ws[r + 1, 6] = "Русский язык"
              ws[r + 1, 7] = "Сумма баллов за вступительные испытания"
              ws[r + 1, 8] = "Баллы за индивидуальные достижения"
              ws[r + 1, 9] = "Сумма конкурсных баллов"
              ws[r + 1, 10] = "Наличие согласия на зачисление"
              ws[r + 1, 11] = "Наличие преимущественного права на зачисление"
              n = 0
              applications.each do |application, values|
                r += 1
                n += 1
                ws[r + 1, 1] = n
                ws[r + 1, 2] = "%04d" % application.application_number
                ws[r + 1, 3] = application.fio
                ws[r + 1, 4] = values[:chemistry]
                ws[r + 1, 5] = values[:biology]
                ws[r + 1, 6] = values[:russian]
                ws[r + 1, 7] = values[:summa]
                ws[r + 1, 8] = values[:achievement]
                ws[r + 1, 9] = values[:full_summa]
                ws[r + 1, 10] = "да" if values[:budget_agr] == competitive_group.id && values[:original_received]
                ws[n + 1, 11] = "да" if application.benefit
              end
              r += 3
            end
          end
          ws.max_rows = r - 2
          ws.max_cols = 11
          ws.save
        else
          applications = applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.enrolled != competitive_group.id}
          ws[1, 1] = "№№"
          ws[1, 2] = "№ личного дела"
          ws[1, 3] = "Ф.И.О."
          ws[1, 4] = "Химия"
          ws[1, 5] = "Биология"
          ws[1, 6] = "Русский язык"
          ws[1, 7] = "Сумма баллов за вступительные испытания"
          ws[1, 8] = "Баллы за индивидуальные достижения"
          ws[1, 9] = "Сумма конкурсных баллов"
          ws[1, 10] = "Наличие согласия на зачисление"
          ws[1, 11] = "Наличие договора"
          ws[1, 12] = "Зачислен по другому конкурсу"
          ws[1, 13] = "Наличие преимущественного права на зачисление"
          n = 0
          if ws.max_rows > 3
            ws.delete_rows(2, ws.max_rows - 2)
            ws.save
          end
          applications.each do |application, values|
            n += 1
            ws[n + 1, 1] = n
            ws[n + 1, 2] = "%04d" % application.application_number
            ws[n + 1, 3] = application.fio
            ws[n + 1, 4] = values[:chemistry]
            ws[n + 1, 5] = values[:biology]
            ws[n + 1, 6] = values[:russian]
            ws[n + 1, 7] = values[:summa]
            ws[n + 1, 8] = values[:achievement]
            ws[n + 1, 9] = values[:full_summa]
            if competitive_group.education_source_id == 15
              ws[n + 1, 10] = "да" if values[:paid_agr] == competitive_group.id && values[:original_received]
            else
              ws[n + 1, 10] = "да" if values[:budget_agr] == competitive_group.id && values[:original_received] 
            end
            ws[n + 1, 11] = "да" if application.contracts.include?(competitive_group.id)
            ws[n + 1, 12] = all_competitive_groups.find(application.enrolled).name if application.enrolled && application.exeptioned != application.enrolled
            ws[n + 1, 13] = "да" if application.benefit
          end
          ws.max_rows = n + 2
          ws.max_cols = 13
          ws.save
        end
      end
    end
  end
  
  task custom_import: :environment do
    request(status_id: 2)
  end
  
  private
  
  def request(options = {})
    case Rails.env
      when 'development' then url = 'priem.edu.ru:8000'
      when 'production' then url = '127.0.0.1:8080'
    end
    method = '/validate'
    request = data(options)
    uri = URI.parse('http://' + url + '/import/importservice.svc')
    http = Net::HTTP.new(uri.host, uri.port)
    headers = {'Content-Type' => 'text/xml'}
    response = http.post(uri.path + method, request, headers)
    puts Nokogiri::XML(response.body).to_xml(encoding: 'UTF-8')
  end
  
  def data(options = {})
    data = ::Builder::XmlMarkup.new(indent: 2)
    data.Root do |root|
      root.AuthData do |ad|
        ad.Login ENV['LOGIN']
        ad.Pass ENV['PASSWORD']
      end
      data.PackageData do |pd|
    campaign = Campaign.first
    applications = campaign.entrant_applications.includes(:identity_documents, :education_document, :marks, :competitive_groups, :subjects).where(status_id: [4, 6]).joins(:institution_achievements)
    
    pd.Applications do |as|
      applications.each do |item|
        as.Application do |a|
          a.UID [campaign.year_start, "%04d" % item.application_number].join('-')
          a.ApplicationNumber [campaign.year_start, "%04d" % item.application_number].join('-')
          a.Entrant do |e|
            e.UID [campaign.year_start, "%04d" % item.application_number].join('-')
            e.LastName item.entrant_last_name
            e.FirstName item.entrant_first_name
            e.MiddleName item.entrant_middle_name if item.entrant_middle_name
            e.GenderID item.gender_id
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
          a.StatusID options[:status_id] ? options[:status_id] : item.status_id
          a.FinSourceAndEduForms do |fsaefs|
            item.competitive_groups.each do |sub_item|
              fsaefs.FinSourceEduForm do |fsef|
                fsef.CompetitiveGroupUID sub_item.id
                fsef.TargetOrganizationUID item.target_organization_id if sub_item.education_source_id == 16 && item.target_organization_id
                fsef.IsAgreedDate item.registration_date.to_datetime.to_s.gsub('+00', '+03') if item.budget_agr == sub_item.id || item.paid_agr == sub_item.id
              end
            end
          end
          a.ApplicationDocuments do |ads|
            identity_document = item.identity_documents.last
            ads.IdentityDocument do |id|
              id.UID ["id", campaign.year_start, identity_document.id].join('-')
              id.DocumentSeries identity_document.identity_document_series ?  identity_document.identity_document_series : "нет серии"
              id.DocumentNumber identity_document.identity_document_number
              id.DocumentDate identity_document.identity_document_date
              id.IdentityDocumentTypeID identity_document.identity_document_type
              id.NationalityTypeID  item.nationality_type_id
              id.BirthDate item.birth_date
            end
            ads.EduDocuments do |eds|
              edu_document = item.education_document
              eds.EduDocument do |ed|
                case edu_document.education_document_type
                when "SchoolCertificateDocument"
                  ed.SchoolCertificateDocument do |scd|
                    scd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                    scd.OriginalReceivedDate edu_document.original_received_date if edu_document.original_received_date
                    if edu_document.education_document_date.year > 2013
                      scd.DocumentNumber edu_document.education_document_number
                    else
                      scd.DocumentSeries edu_document.education_document_number.first(4)
                      scd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 4)
                    end
                    scd.DocumentDate edu_document.education_document_date
                  end
                when "MiddleEduDiplomaDocument"
                  ed.MiddleEduDiplomaDocument do |medd|
                    medd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                    medd.OriginalReceivedDate edu_document.original_received_date if edu_document.original_received_date
                    if edu_document.education_document_date.year > 2013
                      medd.DocumentSeries edu_document.education_document_number.first(6)
                      medd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 6)
                    else
                      medd.DocumentSeries edu_document.education_document_number.first(5)
                      medd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 5)
                    end
                    medd.DocumentDate edu_document.education_document_date
                  end
                when "HighEduDiplomaDocument"
                  ed.HighEduDiplomaDocument do |hedd|
                    hedd.UID ["ed", campaign.year_start, edu_document.id].join('-')
                    hedd.OriginalReceivedDate edu_document.original_received_date if edu_document.original_received_date
                    hedd.DocumentSeries edu_document.education_document_number.first(3)
                    hedd.DocumentNumber edu_document.education_document_number.last(edu_document.education_document_number.size - 3)
                    hedd.DocumentDate edu_document.education_document_date
                  end
                end
              end
            end
            achievements = item.institution_achievements.where.not(id_category: 8)
            unless achievements.empty?
              ads.CustomDocuments do |cds|
                achievements.each do |sub_item|
                    cds.CustomDocument do |cd|
                      cd.UID ["ach", campaign.year_start, item.education_document.id].join('-')
                      case sub_item.id_category
                      when 9
                        cd.DocumentName "Аттестат о среднем общем образовании с отличием"
                        cd.DocumentDate item.education_document.education_document_date
                        cd.DocumentOrganization "Организация СО"
                      when 15
                        cd.DocumentName "Аттестат о среднем (полном) общем образовании для награжденных золотой медалью"
                        cd.DocumentDate item.education_document.education_document_date
                        cd.DocumentOrganization "Организация СО"
                      when 16
                        cd.DocumentName "Аттестат о среднем (полном) общем образовании для награжденных золотой медалью"
                        cd.DocumentDate item.education_document.education_document_date
                        cd.DocumentOrganization "Организация СО"
                      when 17
                        cd.DocumentName "Диплом о среднем профессиональном образовании с отличием"
                        cd.DocumentDate item.education_document.education_document_date
                        cd.DocumentOrganization "Организация СПО"
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
                  when sub_item.form == "Экзамен"
                    etr.ResultSourceTypeID 2
                  end
                  etr.EntranceTestSubject do |ets|
                    ets.SubjectID sub_item.subject.subject_id
#                     ets.SubjectName sub_item.subject.subject_name
                  end
                  etr.EntranceTestTypeID sub_item.subject.entrance_test_item.entrance_test_type_id
                  etr.CompetitiveGroupUID cg.id
                  if sub_item.form == "Экзамен"
                    etr.ResultDocument do |rd|
                      rd.InstitutionDocument do |id|
                        case sub_item.subject.subject_id
                        when 11
                          id.DocumentNumber "2016-1"
                          id.DocumentDate "2016-07-14"
                        when 4
                          id.DocumentNumber "2016-2"
                          id.DocumentDate "2016-07-19"
                        when 1
                          id.DocumentNumber "2016-3"
                          id.DocumentDate "2016-07-22"
                        end
                        id.DocumentTypeID 1
                      end
                    end
                  end
                end
              end
            end
          end
          achievements = item.institution_achievements.where.not(id_category: 8)
          unless achievements.empty?
            a.IndividualAchievements do |ias|
              achievements.each do |sub_item|
                ias.IndividualAchievement do |ia|
                  ia.IAUID [campaign.year_start, "%04d" % item.application_number, sub_item.id_category].join('-')
                  ia.InstitutionAchievementUID sub_item.id
                  ia.IAMark sub_item.max_value
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
  
  def self.applications_del(pd, params)
    campaign = Campaign.find(params[:campaign_id])
    applications = campaign.entrant_applications.joins(:institution_achievements)
    
    pd.Applications do |as|
      applications.each do |item|
        as.Application do |a|
          a.ApplicationNumber [campaign.year_start, "%04d" % item.application_number].join('-')
          a.RegistrationDate item.registration_date.to_datetime.to_s.gsub('+00', '+03')
        end
      end
    end
  end
  
end
