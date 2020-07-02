class Campaign < ActiveRecord::Base
  has_many :admission_volumes, dependent: :destroy
  has_many :distributed_admission_volumes, through: :admission_volumes
  has_many :competitive_groups, dependent: :destroy
  has_many :competitive_group_items, through: :competitive_groups
  has_many :institution_achievements, dependent: :destroy
  has_many :entrant_applications, dependent: :destroy
  has_many :marks, through: :entrant_applications
  has_many :achievements, through: :entrant_applications
  has_many :entrance_test_items, through: :competitive_groups
  has_many :subjects, through: :entrance_test_items
  
  validates :name, :year_start, :year_end, :status_id, :campaign_type_id, :education_forms, :education_levels, presence: true
  validates :year_start, :year_end, numericality: { only_integer: true }
  validates :year_start, :year_end, length: { is: 4 }

  def self.import_admission_volumes(params)
    # определяем приемную кампанию
    campaign = Campaign.find(params[:campaign_id]) 
    
    # загружаем список направлений подготовки и объемов приема
    file = open_spreadsheet(params[:file])
    # получаем список направлений подготовки и кодов
    method = '/dictionarydetails'
    request = Request.data('/dictionarydetails', {dictionary_number: 10})
    http_params = Request.http_params()
    http = Net::HTTP.new(http_params[:uri_host], http_params[:uri_port], http_params[:proxy_ip], http_params[:proxy_port])
    headers = {'Content-Type' => 'text/xml'}
    response = http.post(http_params[:uri_path] + method, request, headers)
    xml = Nokogiri::XML(response.body)
    header = file.row(1)
    admissions = {}
    (2..file.last_row).to_a.each do |i|
      row = Hash[[header, file.row(i)].transpose]
      code = row["Код направления подготовки"]
      if xml.at("NewCode:contains('#{code}')")
        direction_id = xml.at("NewCode:contains('#{code}')").parent.at_css("ID").text
        name = xml.at("NewCode:contains('#{code}')").parent.at_css("Name").text
        admissions[code] = {}
        admissions[code]['direction_id'] = direction_id
        admissions[code]['name'] = name
        admissions[code]['number_budget_o'] = row["Количество бюджетных мест"].to_i > 0  ? row["Количество бюджетных мест"] : 0
        admissions[code]['number_paid_o'] = row["Количество внебюджетных мест"].to_i > 0 ? row["Количество внебюджетных мест"] : 0
        admissions[code]['number_target_o'] = row["Количество целевых мест"].to_i > 0 ? row["Количество целевых мест"] : 0
        admissions[code]['number_quota_o'] = row["Количество мест особой квоты"].to_i > 0 ? row["Количество мест особой квоты"] : 0 
      end
    end

    # заполняем справочники
    # добавляем образовательные программы
    admissions.each do |code, values|
      EduProgram.create(name: values['name'], code: code) unless EduProgram.find_by_code(code)
    end

    admissions.each do |code, values|
      # добавляем объемы приема
      education_level_id = campaign.education_levels.include?(5) ? 5 : 18
      attrib = {education_level_id: education_level_id, direction_id: values['direction_id']}
      attrib.merge!(values.select{|i| i =~ /number/})
      admission_volume = campaign.admission_volumes.find_by_direction_id(values['direction_id']) || campaign.admission_volumes.new
      admission_volume.attributes = attrib
      if admission_volume.save!
        # распределяем места по источникам финансирования
        attrib = {level_budget_id: 1}
        attrib.merge!(values.select{|i| i =~ /budget|target|quota/})
        distributed_admission_volume = admission_volume.distributed_admission_volumes.find_by_level_budget_id(1) || admission_volume.distributed_admission_volumes.new
        distributed_admission_volume.attributes = attrib
        distributed_admission_volume.save!
        numbers = values.select{|i| i =~ /number/}
        numbers.each do |name, number|
          case name
          when 'number_budget_o'
            competitive_group_name = "#{values['name']}. Бюджет." if number.to_i > 0
            education_source_id = 14
          when 'number_paid_o'
            competitive_group_name = "#{values['name']}. Внебюджет." if number.to_i > 0
            education_source_id = 15
          when 'number_target_o'
            competitive_group_name = "#{values['name']}. Целевые места." if number.to_i > 0
            education_source_id = 16
          when 'number_quota_o'
            competitive_group_name = "#{values['name']}. Квота особого права." if number.to_i > 0
            education_source_id = 20
          end
          if competitive_group_name
            # добавляем конкурсные группы
            competitive_group = campaign.competitive_groups.find_by_name(competitive_group_name) || campaign.competitive_groups.create(name: competitive_group_name, education_level_id: campaign.education_levels.first, education_source_id: education_source_id, education_form_id: campaign.education_forms.first, direction_id: values['direction_id'])
            # добавляем элементы конкурсных групп
            competitive_group_item = competitive_group.competitive_group_item || CompetitiveGroupItem.new
            competitive_group_item.attributes = {name => number, competitive_group_id: competitive_group.id}
            competitive_group_item.save!
            # прикрепляем образовательные программы
            competitive_group.edu_programs = []
            competitive_group.edu_programs << EduProgram.find_by_code(code)
          end
        end
      end
    end

    # прикрепляем вступительные испытания к конкурсным группам
    if campaign.education_levels.include?(5)
      campaign.competitive_groups.each{|cg| cg.entrance_test_items = []; cg.entrance_test_items << EntranceTestItem.where(min_score: 42).select{|i| i.created_at.year == campaign.year_start}}
    else
      campaign.competitive_groups.each{|cg| cg.entrance_test_items = []; cg.entrance_test_items << EntranceTestItem.where(min_score: 70).select{|i| i.created_at.year == campaign.year_start}}
    end
  end

  def self.import_institution_achievements(params)
    # определяем приемную кампанию
    campaign = Campaign.find(params[:campaign_id]) 
    
    # загружаем список направлений подготовки и объемов приема
    file = open_spreadsheet(params[:file])
    header = file.row(1)
    achievements = {}
    (2..file.last_row).to_a.each do |i|
      row = Hash[[header, file.row(i)].transpose]
      campaign.institution_achievements.create(name: row['Название достижения'], id_category: row['Категория достижения'], max_value: row['Максимальный балл'])
    end
  end

  private
  def self.open_spreadsheet(file)
    Roo::CSV.new(file.path)
  end
end
