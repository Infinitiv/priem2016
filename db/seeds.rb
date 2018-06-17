# 2017

# загружаем список направлений подготовки и объемов приема
file = Roo::CSV.new('admission_volumes.csv')
# получаем список направлений подготовки и кодов
case Rails.env
  when 'development'
    url = 'priem.edu.ru:8000'
    proxy_ip = nil
    proxy_port = nil
  when 'production' 
    url = '10.0.3.1:8080'
    proxy_ip = '87.255.247.34'
    proxy_port = '3333'
end
method = '/dictionarydetails'
request = '<Root><AuthData><Login>priem@isma.ivanovo.ru</Login><Pass>FdW5jz7e</Pass></AuthData><GetDictionaryContent><DictionaryCode>10</DictionaryCode></GetDictionaryContent></Root>'
uri = URI.parse('http://' + url + '/import/importservice.svc')
http = Net::HTTP.new(uri.host, uri.port, proxy_ip, proxy_port)
headers = {'Content-Type' => 'text/xml'}
response = http.post(uri.path + method, request, headers)
body = Nokogiri::XML(response.body)
header = file.row(1)
admissions = {}
(2..file.last_row).to_a.each do |i|
  row = Hash[[header, file.row(i)].transpose]
  code = row["Код направления подготовки"]
  if body.at("NewCode:contains('#{code}')")
    direction_id = name = body.at("NewCode:contains('#{code}')").parent.at_css("ID").text
    name = body.at("NewCode:contains('#{code}')").parent.at_css("Name").text
    admissions[code] = {}
    admissions[code]['direction_id'] = direction_id
    admissions[code]['name'] = name
    admissions[code]['number_budget_o'] = row["Количество бюджетных мест"] if row["Количество бюджетных мест"] > 0 
    admissions[code]['number_paid_o'] = row["Количество внебюджетных мест"] if row["Количество внебюджетных мест"] > 0
    admissions[code]['number_target_o'] = row["Количество целевых мест"] if row["Количество целевых мест"] > 0
  end
end
# заполняем справочники
# добавляем заказчиков целевого приема
TargetOrganization.create(id: 43, target_organization_name: 'Министерство здравоохранения Чеченской республики')

# добавляем образовательные программы
admissions.each do |code, values|
  EduProgram.create(name: values['name'], code: code) unless EduProgram.find_by_code(code)
end

# добавляем вступительные испытания
subject = Subject.create(subject_name: "Здравоохранение")
subject.entrance_test_items.create(entrance_test_type_id: 1, min_score: 70, entrance_test_priority: 1)

# добавялем приемную кампанию
campaign = Campaign.create(name: "Кадры высшей квалификации", year_start: 2017, year_end: 2017, status_id: 1, campaign_type_id: 4, education_forms: [11], education_levels: [18])

# добавляем индивидуальные достижения
campaign.institution_achievements.create(name: "Стипендиаты Президента Российской Федерации, Правительства Российской Федерации", id_category: 13, max_value: 100)
campaign.institution_achievements.create(name: "Стипендиаты именных стипендий", id_category: 13, max_value: 50)
campaign.institution_achievements.create(name: "Документ установленного образца с отличием", id_category: 13, max_value: 100)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников менее 3 лет", id_category: 13, max_value: 50)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников 3 и более лет", id_category: 13, max_value: 80)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников в сельской местности", id_category: 13, max_value: 90)
campaign.institution_achievements.create(name: "Достижения образовательной организации", id_category: 13, max_value: 50)


admissions.each do |code, values|
  # добавляем объемы приема
  admission_volume = campaign.admission_volumes.create(education_level_id: 18, direction_id: values['direction_id'], values.select{|i| i =~ /number/})
  # распределяем места по источникам финансирования
  admission_volume.distributed_admission_volumes.create(level_budget_id: 1, values.select{|i| i =~ /budget|target/})
  if values['number_budget_o']
    # добавляем конкурсные группы (Бюджет)
    competitive_group = campaign.competitive_groups.create(name: "#{values['name']}. Бюджет.", education_level_id: 18, education_source_id: 14, education_form_id: 11, direction_id: values['direction_id'])
    # добавляем элементы конкурсных групп
    competitive_group.competitive_group_items.create(number_budget_o: values['number_budget_o'], number_paid_o: values['number_paid_o'], number_target_o: values['number_target_o'])
    # прикрепляем образовательные программы
    competitive_group.edu_programs << EduProgram.find_by_code(code)
  end
  if values['number_paid_o']
    # добавляем конкурсные группы (Внебюджет)
    competitive_group = campaign.competitive_groups.create(name: "#{values['name']}. Внебюджет.", education_level_id: 18, education_source_id: 15, education_form_id: 11, direction_id: values['direction_id'])
    # добавляем элементы конкурсных групп
    competitive_group.competitive_group_items.create(number_paid_o: values['number_paid_o'])
    # прикрепляем образовательные программы
    competitive_group.edu_programs << EduProgram.find_by_code(code)
  end
  if values['number_target_o']
    # добавляем конкурсные группы (Целевой прием)
    competitive_group = campaign.competitive_groups.create(name: "#{values['name']}. Бюджет.", education_level_id: 18, education_source_id: 16, education_form_id: 11, direction_id: values['direction_id'])
    # добавляем элементы конкурсных групп
    competitive_group.competitive_group_items.create(number_target_o: values['number_target_o'])
    # прикрепляем образовательные программы
    competitive_group.edu_programs << EduProgram.find_by_code(code)
  end
end



competitive_group = campaign.competitive_groups.create(name: "Акушерство и гинекология. Внебюджет.", education_level_id: 18, education_source_id: 15, education_form_id: 11, direction_id: 17678)
# добавляем элементы конкурсных групп
competitive_group.competitive_group_items.create(number_budget_o: 0, number_paid_o: 5, number_target_o: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.08.01")

competitive_group = campaign.competitive_groups.create(name: "Акушерство и гинекология. Целевые места.", education_level_id: 18, education_source_id: 16, education_form_id: 11, direction_id: 17678)
# добавляем элементы конкурсных групп
competitive_group.competitive_group_items.create(number_budget_o: 0, number_paid_o: 0, number_target_o: 4)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.08.01")
# создаем целевые места
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Владимирской области').id, number_target_o: 1)
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Ивановской области').id, number_target_o: 2)
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Костромской области').id, number_target_o: 1)

# прикрепляем вступительные испытания к конкурсным группам
campaign.competitive_groups.each{|cg| cg.entrance_test_items << EntranceTestItem.where(min_score: 70)}
