class Campaign < ActiveRecord::Base
  require 'net/http'
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
  has_many :identity_documents, through: :entrant_applications
  
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
    competitive_groups = {}
    admission_volumes = {}
    (2..file.last_row).to_a.each do |i|
      row = Hash[[header, file.row(i)].transpose]
      code = row["Код направления подготовки"]
      if xml.at("NewCode:contains('#{code}')")
        direction_id = xml.at("NewCode:contains('#{code}')").parent.at_css("ID").text
        admission_volumes[direction_id] ||= {}
        education_level_id = campaign.education_levels.include?(5) ? 5 : 18
        admission_volumes[direction_id][:education_level_id] = education_level_id
        name = xml.at("NewCode:contains('#{code}')").parent.at_css("Name").text
        case row['Источник финасирования']
        when 'бюджетный прием'
          competitive_group_name = "#{name}. Бюджет."
          education_source_id = 14
          admission_volumes[direction_id][:number_budget_o] ||= 0
          admission_volumes[direction_id][:number_budget_o] += row['Количество мест'].to_i
        when 'внебюджетный прием'
          competitive_group_name = "#{name}. Внебюджет."
          education_source_id = 15
          admission_volumes[direction_id][:number_paid_o] ||= 0
          admission_volumes[direction_id][:number_paid_o] += row['Количество мест'].to_i
        when 'целевой прием'
          target_organization = TargetOrganization.find(row['Заказчик'])
          competitive_group_name = "#{name}. Целевые места. #{target_organization.target_organization_name}."
          education_source_id = 16
          admission_volumes[direction_id][:number_target_o] ||= 0
          admission_volumes[direction_id][:number_target_o] += row['Количество мест'].to_i
        when 'особая квота'
          competitive_group_name = "#{name}. Квота особого права."
          education_source_id = 20
          admission_volumes[direction_id][:number_quota_o] ||= 0
          admission_volumes[direction_id][:number_quota_o] += row['Количество мест'].to_i
        end
        competitive_groups[competitive_group_name] = {}
        competitive_groups[competitive_group_name][:code] = code
        competitive_groups[competitive_group_name][:direction_id] = direction_id
        competitive_groups[competitive_group_name][:education_source_id] = education_source_id
          competitive_groups[competitive_group_name][:target_organization_id] = target_organization.id if education_source_id == 16
        competitive_groups[competitive_group_name][:number] = row['Количество мест'].to_i
        competitive_groups[competitive_group_name][:application_start_date] = row['Дата начала приема заявлений']
        competitive_groups[competitive_group_name][:application_end_exam_date] = row['Дата окончания приема заявлений для ВИ']
        competitive_groups[competitive_group_name][:application_end_ege_date] = row['Дата окончания приема заявлений для ЕГЭ']
        competitive_groups[competitive_group_name][:order_end_date] = row['Дата издания последнего приказа о зачислении']
      end
    end

    # заполняем справочники
    # добавляем образовательные программы
    competitive_groups.each do |competitive_group_name, values|
      EduProgram.create(name: competitive_group_name, code: values[:code]) unless EduProgram.find_by_code(values[:code])
    end

    admission_volumes.each do |direction_id, values|
      # добавляем объемы приема
      education_level_id = campaign.education_levels.include?(5) ? 5 : 18
      attrib = {direction_id: direction_id}.merge!(values)
      admission_volume = campaign.admission_volumes.find_by_direction_id(direction_id) || campaign.admission_volumes.new
      admission_volume.attributes = attrib
      if admission_volume.save!
        # распределяем места по источникам финансирования
        attrib.merge!({level_budget_id: 1})
        distributed_admission_volume = admission_volume.distributed_admission_volumes.find_by_level_budget_id(1) || admission_volume.distributed_admission_volumes.new
        distributed_admission_volume.attributes = attrib.slice(:level_budget_id, :number_budget_o, :number_target_o, :number_quota_o)
        distributed_admission_volume.save!
      end
    end
    competitive_groups.each do |competitive_group_name, values|
      if competitive_group_name
        # добавляем конкурсные группы
        competitive_group = campaign.competitive_groups.find_by_name(competitive_group_name) || campaign.competitive_groups.create(
          name: competitive_group_name,
          education_level_id: campaign.education_levels.first,
          education_source_id: values[:education_source_id],
          education_form_id: campaign.education_forms.first,
          direction_id: values[:direction_id],
          application_start_date: values[:application_start_date],
          application_end_exam_date: values[:application_end_exam_date],
          application_end_ege_date: values[:application_end_ege_date],
          order_end_date: values[:order_end_date]
        )
        if competitive_group.education_source_id == 16
          target_number = competitive_group.target_numbers.find_by_target_organization_id(values[:target_organization_id]) || competitive_group.target_numbers.create(target_organization_id: values[:target_organization_id], number_target_o: values[:number])
        end
        # добавляем элементы конкурсных групп
        attrib = {}
        case values[:education_source_id]
        when 14
          number = {number_budget_o: values[:number]}
        when 15
          number = {number_paid_o: values[:number]}
        when 16
          number = {number_target_o: values[:number]}
        when 20
          number = {number_quota_o: values[:number]}
        end
        attrib.merge!(number)
        competitive_group_item = competitive_group.competitive_group_item || CompetitiveGroupItem.new
        competitive_group_item.competitive_group_id = competitive_group.id
        competitive_group_item.attributes = attrib
        competitive_group_item.save!
        # прикрепляем образовательные программы
        competitive_group.edu_programs = []
        competitive_group.edu_programs << EduProgram.find_by_code(values[:code])
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
