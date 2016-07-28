namespace :priem do
  desc "Publish competition lists to google drive"
  task competition_lists: :environment do
    
    campaign = Campaign.first
    admission_volume_hash = EntrantApplication.admission_volume_hash(campaign)
    applications_hash = EntrantApplication.applications_hash(campaign)
    target_organizations = TargetOrganization.order(:target_organization_name)

    session = GoogleDrive.saved_session("config/google_drive.json")
    case Rails.env
      when 'development'
        s = session.spreadsheet_by_key("1YTVWLPoB8-ADiyOKNiwyo94R_B33WghIGZ0h8-IHuqw")
      when 'production'
        s = session.spreadsheet_by_key("1BFjqg-cdIHAfZit78v8Y_tk8sDBHOfckghZVKkjnX2E")        
    end
    s.title = "Конкурсные списки"
    
    admission_volume_hash.each do |direction_id, competitive_groups|
      competitive_groups.select{|k, v| k.is_for_krym == false}.each do |competitive_group, numbers|
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
          applications = applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id)}
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
          ws[1, 11] = "Наличие преимущественного права на зачисление"
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
            ws[n + 1, 11] = "да" if application.benefit
          end
          ws.max_rows = n + 2
          ws.max_cols = 11
          ws.save
        end
      end
    end
  end

end
