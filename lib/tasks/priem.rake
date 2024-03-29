namespace :priem do
  require 'builder'
  require 'json'
  require 'net/http'
  
  task check_addresses: :environment do
    entrant_applications = EntrantApplication.includes(:campaign).where.not(address: nil).where(address_suggestions: nil, status_id: [4, 6])
    nn = entrant_applications.count
    puts "Найдено записей для обработки: #{nn}"
    url = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address'
    token = ENV['DADATA_TOKEN']
    headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Token #{token}"}

    uri = URI.parse(url)
    n = 1
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      entrant_applications.each do |entrant_application|
        puts "Обрабатываем запись #{n} из #{nn}"
        data = {}
        request = { "query": "#{[entrant_application.zip_code, entrant_application.address].compact.join(', ')}" }.to_json
        response = http.post(uri.path, request, headers)
        data = JSON.parse(response.body)
        unless data['suggestions'].empty?
          entrant_application.address_suggestions = data['suggestions']
          if data['suggestions'].size == 1
            entrant_application.verified_address = data['suggestions'].first['unrestricted_value']
            entrant_application.region_iso_code = data['suggestions'].first['data']['region_iso_code']
            entrant_application.region_with_type = data['suggestions'].first['data']['region_with_type']
            entrant_application.geo_lat = data['suggestions'].first['data']['geo_lat']
            entrant_application.geo_lon = data['suggestions'].first['data']['geo_lon']
          else
            puts "Найдено более одного возможного адреса ((("
          end
          if entrant_application.save!
            puts 'Запись успешно обновлена'
          else
            puts 'Что-то пошло не так!'
          end
        else
          puts "Не найдено подходящих вариантов для адреса #{entrant_application.address}. Поступающий # #{[entrant_application.campaign.year_start, entrant_application.application_number].join('-')}"
        end
        n += 1
      end
    end
  end
  
  task check_application: :environment do 
    campaign = Campaign.where(campaign_type_id: 1).last
    if Time.now.to_date > Date.new(2021, 7, 29)
      applications = campaign.entrant_applications.select(:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :registration_date, :olympionic).order(:application_number).joins(:marks).where(status_id: [4, 6]).where("registration_date > ?", Date.new(2021, 07, 29)).uniq
    else  
      applications = campaign.entrant_applications.select(:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :registration_date, :olympionic).order(:application_number).joins(:marks).where(status_id: [4, 6]).uniq
    end
    applications.each do |application|
      application_number = [application.campaign.year_start, "%04d" % application.application_number, 's'].join('-')
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
          ca.ApplicationNumber application_number
        end
      end
      request = data.target!
      uri = URI.parse('http://' + url + '/import/importservice.svc')
      http = Net::HTTP.new(uri.host, uri.port, proxy_ip, proxy_port)
      headers = {'Content-Type' => 'text/xml'}
      puts "поступающий #{application_number} - отправляем запрос"
      response = http.post(uri.path + method, request, headers)
      xml = Nokogiri::XML(response.body)
      xml.css('Mark').each do |mark|
        if Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i)
          new_value = mark.at_css('SubjectMark').text.to_i
          old_value_ege = application.marks.where(subject_id: Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i).id, form: 'ЕГЭ').map(&:value).max.to_i
          old_value_exam = application.marks.where(subject_id: Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i).id, form: 'ВИ').map(&:value).max.to_i
          application.marks.where(subject_id: Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i).id, form: 'ЕГЭ').each do |m|
            m.update_attributes(value: new_value, checked: Time.now.to_date)
            puts "оценка по предмету #{mark.at_css('SubjectName').text} обновлена с #{old_value_ege} на #{new_value}"
          end
          application.marks.where(subject_id: Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i).id, form: 'ВИ').each do |m|
            if new_value > old_value_exam
              m.update_attributes(value: new_value, form: 'ЕГЭ', checked: Time.now.to_date)
              puts "оценка по предмету #{mark.at_css('SubjectName').text} обновлена с #{old_value_exam} на #{new_value}, форма экзамена изменена на ЕГЭ"
            end
          end
          if application.olympionic
            application.olympic_documents.each do |olympic_document|
              if olympic_document.benefit_type_id == 3 && olympic_document.ege_subject_id == mark.at_css('SubjectID').text.to_i
                application.marks.where(subject_id: Subject.find_by_subject_id(mark.at_css('SubjectID').text.to_i).id, form: 'ЕГЭ').update_all(form: 'Олимпиада', value: 100, checked: Time.now.to_date) if mark.at_css('SubjectMark').text.to_i > 74
                puts "добавлена оценка за олимпиаду по #{mark.at_css('SubjectName').text}"
              end
            end
          end
        end
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
  
  desc 'Target export'
  task target_export: :environment do
    %x(mkdir -p storage/target)
    target_competitive_groups = CompetitiveGroup.where(campaign_id: 9, education_source_id: 16).map(&:id)
    
    entrant_applications = EntrantApplication.where(enrolled: target_competitive_groups)
    entrant_applications.each do |entrant_application|
      entrant_application_path = "storage/target/#{CompetitiveGroup.find(entrant_application.enrolled).name}/#{entrant_application.application_number}"
      %x(mkdir -p "#{entrant_application_path}")
      marks_ege = entrant_application.marks.where(form: 'ЕГЭ')
      marks_exam = entrant_application.marks.where.not(form: 'ЕГЭ')
      mean_ege = unless marks_ege.empty?
                   marks_ege.pluck(:value).any? ? (marks_ege.pluck(:value).sum.to_f/marks_ege.count).round(2) : 0
                 else
                   0
                 end
      mean_exam = unless marks_exam.empty?
                    marks_exam.pluck(:value).any? ? (marks_exam.pluck(:value).sum.to_f/marks_exam.count).round(2) : 0
                  else
                    0
                  end
      %x(touch "#{entrant_application_path}/#{entrant_application.fio} - #{mean_ege} - #{mean_exam}.txt")
      target_contracts_ids = entrant_application.target_contracts.where(competitive_group_id: entrant_application.enrolled).map(&:id)
      target_attachments = entrant_application.attachments.where(document_type: 'target_contract', document_id: target_contracts_ids)
      target_attachments.each do |target_attachment|
        path = target_attachment.data_hash[0..2].split('').join('/')
        %x(cp "#{Rails.root.join('storage', path, target_attachment.data_hash)}" "#{entrant_application_path}/#{target_attachment.filename}")
      end
    end
  end
  
  desc 'passport export'
  task passport_export: :environment do
    %x(mkdir -p storage/passport)
    entrant_applications = EntrantApplication.where(campaign_id: 9).where.not(enrolled: nil)
    entrant_applications.each do |entrant_application|
      entrant_application_path = "storage/passport/#{entrant_application.application_number}-#{entrant_application.fio}"
      %x(mkdir -p "#{entrant_application_path}")
      passport_attachments = entrant_application.attachments.where(document_type: 'identity_document')
      passport_attachments.each do |passport_attachment|
        path = passport_attachment.data_hash[0..2].split('').join('/')
        %x(cp "#{Rails.root.join('storage', path, passport_attachment.data_hash)}" "#{entrant_application_path}/#{passport_attachment.filename}")
      end
    end
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
    applications = EntrantApplication.order(:application_number).joins(:marks).where(campaign_id: 7, status_id: 4, marks: {form: 'Экзамен', subject_id: 3}).where("application_number > ?", 939).uniq
    test_id = 1963
    exam_ids = {1 => 1942, 2 => 1945, 3 => 1947, 4 => 1948, 5 => 1949, 6 => 1950, 7 => 1951, 8 => 1952, 9 => 1953, 10 => 1954, 11 => 1956, 12 => 1957, 13 => 1958, 14 => 1959, 15 => 1960}
    rows = []
    n = 11
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
      end
      n += 1
      applications = applications - applications.first(9)
    end
    CSV.open("mailing_to_exam.csv", "wb") do |csv|
      csv << rows.first.keys
      rows.each do |row|
        csv << row.values
      end
    end
    if Rails.env == 'production'
      rows.each do |row|
        Events.mailing_to_exam(row).deliver_later 
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
  
  def open_spreadsheet(file)
    Roo::CSV.new([Rails.root, 'lib', 'tasks', 'data', file].join('/'))
  end
  
end
