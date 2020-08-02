namespace :priem do
  require 'builder'
  
  desc 'Publication lists of entrants to google drive'
  task entrants_lists: :environment do
    campaigns = Campaign.where(year_start: Time.now.year)
    campaigns.each do |campaign|
      applications = campaign.entrant_applications.includes([:competitive_groups, :target_organization, :marks]).order(:application_number)
      title_production = "Приемная кампания #{campaign.name}. Заявления, принятые по состоянию на #{applications.last.registration_date.strftime("%d.%m.%Y")}"
      title_development = [title_production, "(тестовая)"].join(" ")
      competitive_groups = campaign.competitive_groups

      session = GoogleDrive.saved_session("config/google_drive.json")
      case Rails.env
        when 'development'
          if campaign.google_key_development
            s = session.spreadsheet_by_key(campaign.google_key_development)
            s.title = title_development
          else
            s = session.create_spreadsheet(title_development)
            campaign.update_attributes(google_key_development: s.key)
          end
        when 'production'
          if campaign.google_key_production
            s = session.spreadsheet_by_key(campaign.google_key_production)
            s.title = title_production
          else
            s = session.create_spreadsheet(title_production)
            campaign.update_attributes(google_key_production: s.key)
          end
      end
      
      ws = s.worksheet_by_title("Список") || s.add_worksheet("Список")
      n = 0
      applications.each do |application|
        n += 1
        ws[n + 2, 1] = "%04d" % application.application_number if ws[n + 2, 2] != "%04d" % application.application_number
        ws[n + 2, 2] = application.fio if ws[n + 2, 3] != application.fio
        form = application.marks.map(&:form).include?("Экзамен") ? "Экзамен" : "ЕГЭ"
        ws[n + 2, 3] = form if ws[n + 2, 4] != form
        entrant_competitive_groups = application.competitive_groups.map(&:name)
        entrant_competitive_groups.include?("Лечебное дело. Бюджет.") && ws[n + 2, 4] != 1 ? ws[n + 2, 4] = 1 : ws[n + 2, 4] = ""
        entrant_competitive_groups.include?("Педиатрия. Бюджет.") && ws[n + 2, 5] != 1 ? ws[n + 2, 5] = 1 : ws[n + 2, 5] = ""
        entrant_competitive_groups.include?("Стоматология. Бюджет.") && ws[n + 2, 6] != 1 ? ws[n + 2, 6] = 1 : ws[n + 2, 6] = ""
        entrant_competitive_groups.include?("Лечебное дело. Внебюджет.") && ws[n + 2, 7] != 1 ? ws[n + 2, 7] = 1 : ws[n + 2, 7] = ""
        entrant_competitive_groups.include?("Педиатрия. Внебюджет.") && ws[n + 2, 8] != 1 ? ws[n + 2, 8] = 1 : ws[n + 2, 8] = ""
        entrant_competitive_groups.include?("Стоматология. Внебюджет.") && ws[n + 2, 9] != 1 ? ws[n + 2, 9] = 1 : ws[n + 2, 9] = ""
        entrant_competitive_groups.include?("Лечебное дело. Целевые места.") && ws[n + 2, 10] != 1 ? ws[n + 2, 10] = 1 : ws[n + 2, 10] = ""
        entrant_competitive_groups.include?("Педиатрия. Целевые места.") && ws[n + 2, 11] != 1 ? ws[n + 2, 11] = 1 : ws[n + 2, 11] = ""
        entrant_competitive_groups.include?("Стоматология. Целевые места.") && ws[n + 2, 12] != 1 ? ws[n + 2, 12] = 1 : ws[n + 2, 12] = ""
				application.target_organization && ws[n + 2, 13] != application.target_organization.target_organization_name ? ws[n + 2, 13] = application.target_organization.target_organization_name : ""
        entrant_competitive_groups.include?("Лечебное дело. Квота особого права.") && ws[n + 2, 14] != 1 ? ws[n + 2, 14] = 1 : ws[n + 2, 14] = ""
        entrant_competitive_groups.include?("Педиатрия. Квота особого права.") && ws[n + 2, 15] != 1 ? ws[n + 2, 15] = 1 : ws[n + 2, 15] = ""
        entrant_competitive_groups.include?("Стоматология. Квота особого права.") && ws[n + 2, 16] != 1 ? ws[n + 2, 16] = 1 : ws[n + 2, 16] = ""
        special_marks = case true
        when application.status_id == 6
        	"Заявление отозвано"
        end
        ws[n + 2, 17] != special_marks ? ws[n + 2, 17] = special_marks : ""
      end
      ws.max_rows = n + 2
    	ws.max_cols = 17
    	ws.save
    end
  end
  
  desc "Publish competition lists to google drive"
  task competition_lists: :environment do
    
    campaigns = Campaign.where(id: 3)
    campaigns.each do |campaign|
      title_production = "Приемная кампания #{campaign.name}. Конкурсные списки по состоянию на #{Time.now.to_datetime.strftime("%F %T")}"
      title_development = [title_production, "(тестовая)"].join(" ")
      admission_volume_hash = EntrantApplication.admission_volume_hash(campaign)
      entrant_applications_hash = EntrantApplication.entrant_applications_hash(campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.sort_by{|k, v| [v[:full_summa].to_i, v[:summa].to_i, v[:marks], v[:benefit]]}.reverse
      target_organizations = TargetOrganization.order(:target_organization_name)
      all_competitive_groups = campaign.competitive_groups

      session = GoogleDrive.saved_session("config/google_drive.json")
      case Rails.env
        when 'development'
          if campaign.google_key_development
            s = session.spreadsheet_by_key(campaign.google_key_development)
            s.title = title_development
          else
            s = session.create_spreadsheet(title_development)
            campaign.update_attributes(google_key_development: s.key)
          end
        when 'production'
          if campaign.google_key_production
            s = session.spreadsheet_by_key(campaign.google_key_production)
            s.title = title_production
          else
            s = session.create_spreadsheet(title_production)
            campaign.update_attributes(google_key_production: s.key)
          end
      end
      admission_volume_hash.each do |direction_id, competitive_groups|
        competitive_groups.select{|cg| [14, 15, 16, 20].include? cg.education_source_id}.each do |competitive_group, numbers|
          s.worksheet_by_title(competitive_group.name).delete if s.worksheet_by_title(competitive_group.name)
          ws = s.add_worksheet(competitive_group.name)
          puts "Заполняем #{competitive_group.name}"
          case competitive_group.education_source_id
          when 16
            r = 1
            target_organizations.each do |target_organization|
            applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.target_organization_id == target_organization.id}
              unless applications.empty?
                ws[r, 1]= target_organization.target_organization_name
                ws[r + 1, 1] = "№№"
                ws[r + 1, 2] = "№ личного дела"
                ws[r + 1, 3] = "Ф.И.О."
                ws[r + 1, 4] = "Оригинал и согласие на зачисление"
                ws[r + 1, 5] = "Сумма конкурсных баллов"
                ws[r + 1, 6] = "Химия"
                ws[r + 1, 7] = "Биология"
                ws[r + 1, 8] = "Русский язык"
                ws[r + 1, 9] = "Сумма баллов за вступительные испытания"
                ws[r + 1, 10] = "Баллы за индивидуальные достижения"
                ws[r + 1, 11] = "Наличие преимущественного права на зачисление"
                n = 0
                applications.each do |application, values|
                  r += 1
                  n += 1
                  ws[r + 1, 1] = n
                  ws[r + 1, 2] = "%04d" % application.application_number
                  ws[r + 1, 3] = application.fio
                  ws[r + 1, 4] = "да" if application.budget_agr == competitive_group.id && values[:original_received]
                  ws[r + 1, 5] = values[:full_summa]
                  ws[r + 1, 6] = values[:marks][0]
                  ws[r + 1, 7] = values[:marks][1]
                  ws[r + 1, 8] = values[:marks][2]
                  ws[r + 1, 9] = values[:summa]
                  ws[r + 1, 10] = values[:achievements_sum]
                  ws[r + 1, 11] = "да" if application.benefit
                end
                r += 3
              end
            end
            ws.max_cols = 11
            ws.max_rows = r - 2
            ws.save
          when 14
            r = 1
            
            applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.enrolled != competitive_group.id && v[:examless]}
            unless applications.empty?
              ws[r, 1] = "Без вступительных испытаний"
              ws[r + 1, 1] = "№№"
              ws[r + 1, 2] = "№ личного дела"
              ws[r + 1, 3] = "Ф.И.О."
              ws[r + 1, 4] = "Основание приема без испытаний"
              ws[r + 1, 5] = "Баллы за индивидуальные достижения"
              ws[r + 1, 6] = "Наличие преимущественного права на зачисление"
              n = 0
              applications.each do |application, values|
                r += 1
                n += 1
                ws[r + 1, 1] = n
                ws[r + 1, 2] = "%04d" % application.application_number
                ws[r + 1, 3] = application.fio
                ws[r + 1, 4] = "Олимпиада"
                ws[r + 1, 5] = values[:achievements_sum]
                ws[r + 1, 6] = "да" if application.benefit
              end
              r += 2
            end
            
            applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.enrolled != competitive_group.id}
            unless applications.empty?
              if r == 1
                r = 0
              else
                ws[r, 1] = "Общий конкурс"
              end
              ws[r + 1, 1] = "№№"
              ws[r + 1, 2] = "№ личного дела"
              ws[r + 1, 3] = "Ф.И.О."
              ws[r + 1, 4] = "Оригинал и согласие на зачисление"
              ws[r + 1, 5] = "Сумма конкурсных баллов"
              ws[r + 1, 6] = "Химия"
              ws[r + 1, 7] = "Биология"
              ws[r + 1, 8] = "Русский язык"
              ws[r + 1, 9] = "Сумма баллов за вступительные испытания"
              ws[r + 1, 10] = "Баллы за индивидуальные достижения"
              ws[r + 1, 11] = "Зачислен по другому конкурсу"
              ws[r + 1, 12] = "Наличие преимущественного права на зачисление"
              n = 0
              applications.each do |application, values|
                r += 1
                n += 1
                ws[r + 1, 1] = n
                ws[r + 1, 2] = "%04d" % application.application_number
                ws[r + 1, 3] = application.fio
                ws[r + 1, 4] = "да" if application.budget_agr == competitive_group.id && values[:original_received]
                ws[r + 1, 5] = values[:full_summa]
                ws[r + 1, 6] = values[:marks][0]
                ws[r + 1, 7] = values[:marks][1]
                ws[r + 1, 8] = values[:marks][2]
                ws[r + 1, 9] = values[:summa]
                ws[r + 1, 10] = values[:achievements_sum]
                ws[r + 1, 11] = all_competitive_groups.find(application.enrolled).name if application.enrolled && application.exeptioned != application.enrolled
                ws[r + 1, 12] = "да" if application.benefit
              end
            end
            ws.max_cols = 12
            ws.max_rows = r + 1
            ws.save
          when 15
            r = 1
            applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.enrolled != competitive_group.id}
            unless applications.empty?
              ws[r, 1] = "№№"
              ws[r, 2] = "№ личного дела"
              ws[r, 3] = "Ф.И.О."
              ws[r, 4] = "Оригинал и согласие на зачисление"
              ws[r, 5] = "Сумма конкурсных баллов"
              ws[r, 6] = "Химия"
              ws[r, 7] = "Биология"
              ws[r, 8] = "Русский язык"
              ws[r, 9] = "Сумма баллов за вступительные испытания"
              ws[r, 10] = "Баллы за индивидуальные достижения"
              ws[r, 11] = "Зачислен по другому конкурсу"
              ws[r, 12] = "Наличие преимущественного права на зачисление"
              n = 0
              applications.each do |application, values|
                r += 1
                n += 1
                ws[r, 1] = n
                ws[r, 2] = "%04d" % application.application_number
                ws[r, 3] = application.fio
                ws[r, 4] = "да" if application.paid_agr == competitive_group.id
                ws[r, 5] = values[:full_summa]
                ws[r, 6] = values[:marks][0]
                ws[r, 7] = values[:marks][1]
                ws[r, 8] = values[:marks][2]
                ws[r, 9] = values[:summa]
                ws[r, 10] = values[:achievements_sum]
                ws[r, 11] = all_competitive_groups.find(application.enrolled).name if application.enrolled && application.exeptioned != application.enrolled
                ws[r, 12] = "да" if application.benefit
              end
            end
            ws.max_cols = 12
            ws.max_rows = r + 1
            ws.save
          when 20
            r = 1
            applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && k.enrolled != competitive_group.id}
            unless applications.empty?
              ws[r, 1] = "№№"
              ws[r, 2] = "№ личного дела"
              ws[r, 3] = "Ф.И.О."
              ws[r, 4] = "Оригинал и согласие на зачисление"
              ws[r, 5] = "Сумма конкурсных баллов"
              ws[r, 6] = "Химия"
              ws[r, 7] = "Биология"
              ws[r, 8] = "Русский язык"
              ws[r, 9] = "Сумма баллов за вступительные испытания"
              ws[r, 10] = "Баллы за индивидуальные достижения"
              n = 0
              applications.each do |application, values|
                r += 1
                n += 1
                ws[r, 1] = n
                ws[r, 2] = "%04d" % application.application_number
                ws[r, 3] = application.fio
                ws[r, 4] = "да" if application.budget_agr == competitive_group.id && values[:original_received]
                ws[r, 5] = values[:full_summa]
                ws[r, 6] = values[:marks][0]
                ws[r, 7] = values[:marks][1]
                ws[r, 8] = values[:marks][2]
                ws[r, 9] = values[:summa]
                ws[r, 10] = values[:achievements_sum]
              end
            end
            ws.max_cols = 10
            ws.max_rows = r + 1
            ws.save
          end
        end
      end
    end
  end
  
  task custom_import: :environment do
    request(status_id: 2)
  end
  
  task check_application: :environment do 
    campaign = Campaign.where(campaign_type_id: 1).last
    applications = campaign.entrant_applications.includes(:marks).where(status_id: 4).first(2)
    applications.each do |application|
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
      method = '/checkapplication/single'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        Request.auth_data(root)
        data.CheckApp do |ca|
          ca.RegistrationDate application.registration_date.to_datetime.to_s.gsub('+00', '+03')
          ca.ApplicationNumber application.application_number
        end
      end
      request = data
      uri = URI.parse('http://' + url + '/import/importservice.svc')
      http = Net::HTTP.new(uri.host, uri.port, proxy_ip, proxy_port)
      headers = {'Content-Type' => 'text/xml'}
      response = http.post(uri.path + method, request, headers)
      xml = Nokogiri::XML(response.body)
      xml.css('Mark').each do |mark|
        application.marks.where(subject_id: mark.at_css('SubjectID').text.to_i, form: 'ЕГЭ').update_all(value: mark.at_css('SubjectMark').text.to_i, checked: Time.now.to_date)
      end
    end
  end
  
  task target_xml: :environment do
    campaign = Campaign.first
    applications = campaign.entrant_applications.includes(:marks, :target_organization).where(enrolled: [6, 12, 18])
    xml = Builder::XmlMarkup.new
    xml.root(id: 2277) do |root|
      n = 0
      applications.each do |item|
        n += 1
        case item.enrolled
        when 6
          spec = 3073
          duration = 6
        when 12
          spec = 3074
          duration = 6
        when 18
          spec = 3075
          duration = 5
        end
        p4_6 = item.target_organization.target_organization_name
        p4_9 = "Министерство здравоохранения Российской федерации"
        case item.target_organization_id
        when 1
          p4_8 = 52556
          p4_10 = 1
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 0
          p4_15 = 0
          p4_16 = 2
        when 2
          p4_8 = 55908
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с постановлением администрации Владимирской области от 07.11.2014 № 1143 Об утверждении Положения о порядке предоставления гражданам в период их обучения в организациях, осуществляющих образовательную деятельность по программама высшего медицинского образования, мер социальной поддрежки в соответствии с заключенным с депаратамментом здравоохранения администрации области договором о целевом обучении'
          p4_15 = 0
          p4_16 = 2
        when 3
          p4_8 = 60696
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'ежемесячная денежная выплата в соответствии с законом Вологодской области от 6 мая 2013 года № 3035-ОЗ О мерах социальной поддержки, направленных на кадровое обеспечение системы здравоохранения области'
          p4_15 = 0
          p4_16 = 2
        when 4
          p4_8 = 74808
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'обеспечить предоставление гражданину в период его обучения меры социальной поддержки в сооответствии с Муниципальными программами (подпрограммами), принятыми в целях привлечения медицинских кадров для работы в учреждениях здравоохранения Ивановской области'
          p4_15 = 0
          p4_16 = 0
        when 5
          p4_8 = 95328
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с действующим законодательством Костромской области, устанавливающим социальные гарантии для медицинских работников Костромской области'
          p4_15 = 0
          p4_16 = 2
        when 6
          p4_8 = 111446
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'ежемесячная выплата, предоставляемая в порядке и сроки, установленные нормативным правовым актом администрации Липецкой области'
          p4_15 = 0
          p4_16 = 2
        when 8
          p4_8 = 197660
          p4_10 = 3
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 0
          p4_15 = 36000
          p4_16 = 2
        when 9
          p4_8 = 215418
          p4_9 = "Федеральное медико-биологическое агентство"
          p4_10 = 0
          p4_11 = 0
          p4_12 = 0
          p4_13 = 0
          p4_14 = 'выплата стипендии в размере, определяемом приказом руководителя Организации, принимаемым в установленном порядке до начала учебного года, при условии успешного освоения учебных дисциплин согласно учебному плану, подтвержденного результатами промежуточной аттестации со средним баллом не ниже 4,0'
          p4_15 = 0
          p4_16 = 3
        end
        root.lines(nom: n) do |lines|
          lines.oo 2277
          lines.spec spec
          lines.fo 1
          lines.id_kladr 74809
          lines.p4_1 [campaign.year_start, "%04d" % item.application_number].join('-')
          lines.p4_2 item.gender_id
          lines.p4_3 campaign.year_start
          lines.p4_4 campaign.year_start + duration
          lines.p4_5 item.marks.sum(:value)/3.to_f
          lines.p4_6 p4_6
          lines.p4_8 p4_8
          lines.p4_9 p4_9
          lines.p4_10 p4_10
          lines.p4_11 p4_11
          lines.p4_12 p4_12
          lines.p4_13 p4_13
          lines.p4_14 p4_14
          lines.p4_15 p4_15
          lines.p4_16 p4_16
          lines.p4_17 p4_6
          lines.p4_19 p4_8
          lines.p4_20 p4_9
        end
      end
    end
    File.open('public/target.xml', "w"){|f| f.write xml}
  end
  
  desc "Fill dictionaries"
  task fill_dictionaries: :environment do
    log_path = [Rails.root, 'log', 'rake.log'].join('/')
    method = '/dictionary'
    request = Request.data(method, nil)
    http_params = http_params()
    http = Net::HTTP.new(http_params[:uri_host], http_params[:uri_port], http_params[:proxy_ip], http_params[:proxy_port])
    headers = {'Content-Type' => 'text/xml'}
    message = 'Подключаюсь к серверу'
    %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
    response = http.post(http_params[:uri_path] + method, request, headers)
    message = 'Получаю ответ'
    %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
    xml = Nokogiri::XML(response.body)
    if xml.css('Dictionary').empty?
      message = 'Что-то пошло не так!'
      %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
      message = response.code
      %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
      message = response.body
      %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
      message = request
      %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
    else
      dictionaries_list = {}
      xml.css('Dictionary').each{ |i| dictionaries_list[i.at('Name').text] = i.at('Code').text.to_i }
      method = '/dictionarydetails'
      dictionaries_list.each do |name, code|
        dictionary = Dictionary.find_by_code(code) || Dictionary.new
        if !dictionary.id || true #dictionary.updated_at < Time.now.to_date - 1
          request = Request.data('/dictionarydetails', {dictionary_number: code})
          response = http.post(http_params[:uri_path] + method, request, headers)
          xml = Nokogiri::XML(response.body)
          dictionary_items_list = []
          xml.css('DictionaryItem').each{|i| dictionary_items_list.push({name: i.at('Name').text, id: i.at('ID').text.to_i}) if i.at('Name')}
          unless dictionary_items_list.empty?
            message = dictionary.id ? "Обновляем справочник #{code} #{name}" : "Добавляем справочник #{code} #{name}"
            %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
            dictionary.attributes = {name: name, code: code, items: dictionary_items_list.as_json}
            if dictionary.save!
              message = "Успешно!"
              %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
            else
              message = "Что-то пошло не так!"
              %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
              message = dictionary
              %x(echo "#{[Time.now, message].join(' - ')}" >> "#{log_path}")
            end
          end
        end
      end
    end
  end
  
  desc 'mailing to exam entrants'
  task mailing_to_exam: :environment do
    applications = EntrantApplication.order(:application_number).joins(:marks).where(campaign_id: 7, status_id: 4, marks: {form: 'Экзамен', subject_id: 3}).uniq
    test_id = 1963
    exam_ids = {1 => 1942, 2 => 1945, 3 => 1947, 4 => 1948, 5 => 1949, 6 => 1950, 7 => 1951, 8 => 1952, 9 => 1953, 10 => 1954, 11 => 1956, 12 => 1957, 13 => 1958, 14 => 1959, 15 => 1960}
    rows = []
    n = 1
    while applications.length > 0
      applications.first(9).each do |application|
        row = {}
        row[:application_number] = application.application_number
        row[:username] = "priem2020_#{application.application_number}"
        row[:lastname] = application.entrant_last_name
        row[:firstname] = application.entrant_first_name
        row[:middlename] = application.entrant_middle_name
        row[:email] = application.email
        row[:password] = %x(pwgen).strip
        row[:start_time] = n <= 8 ? '9:00' : '13:00'
        row[:course1] = 'ОТ2020'
        row[:course2] = "Химия2020_#{n}"
        row[:test_link] = "https://moodle.isma.ivanovo.ru/mod/lti/view.php?id=#{test_id}"
        row[:exam_link] = "https://moodle.isma.ivanovo.ru/mod/lti/view.php?id=#{exam_ids[n]}"
        rows << row
        Events.mailing_to_exam(row).deliver_later if Rails.env == 'production'
      end
      n += 1
      applications = applications - applications.first(9)
    end
    CSV.open("mailing_to_exam.csv", "wb") do |csv|
      csv << rows.first.keys
      rows.sample(5).each do |row|
        csv << row.values
      end
    end
  end
  
  private
  
  def http_params
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
  
  def request(options = {})
    case Rails.env
      when 'development' then url = 'priem.edu.ru:8000'
      when 'production' then url = '127.0.0.1:8080'
    end
    method = '/import'
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
    applications = campaign.entrant_applications
    
    pd.Applications do |as|
      applications.each do |item|
        as.Application do |a|
          a.ApplicationNumber [campaign.year_start, "%04d" % item.application_number].join('-')
          a.RegistrationDate item.registration_date.to_datetime.to_s.gsub('+00', '+03')
        end
      end
    end
  end
  
  def open_spreadsheet(file)
    Roo::CSV.new([Rails.root, 'lib', 'tasks', 'data', file].join('/'))
  end
  
end
