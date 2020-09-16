class EntrantApplication < ActiveRecord::Base
  require 'builder'
  
  belongs_to :campaign
  has_many :marks, dependent: :destroy
  has_many :subjects, through: :marks
  has_one :education_document, dependent: :destroy
  has_many :identity_documents, dependent: :destroy
  has_and_belongs_to_many :institution_achievements
  has_many :benefit_documents, dependent: :destroy
  has_and_belongs_to_many :competitive_groups
  has_many :target_contracts, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :target_organizations, through: :target_contracts
  has_many :achievements, dependent: :destroy
  has_many :olympic_documents, dependent: :destroy
  has_many :other_documents, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :journals, dependent: :destroy
  
#   validates :application_number, :campaign_id, :entrant_last_name, :entrant_first_name, :gender_id, :birth_date, :registration_date, :status_id, :data_hash, presence: true
  
  def fio
    [entrant_last_name, entrant_first_name, entrant_middle_name].compact.join(' ')
  end
  
  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".ods" then Roo::OpenOffice.new(file.path)
    when ".csv" then Roo::CSV.new(file.path)
    when ".xls" then Roo::Excel.new(file.path)
    when ".xlsx" then Roo::Excelx.new(file.path)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
  
  def self.import(file, campaign)
    competitive_groups = campaign.competitive_groups
    accessible_attributes = column_names
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).to_a.each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      entrant_application = campaign.entrant_applications.find_by_application_number(row["application_number"]) || campaign.entrant_applications.new
      entrant_application.attributes = row.to_hash.slice(*accessible_attributes)
      if row.keys.include? 'agreement'
        entrant_application.budget_agr = nil 
        entrant_application.paid_agr = nil
        if row['agreement']
          if row['agreement'] =~ /Внебюджет/
            entrant_application.paid_agr = competitive_groups.find_by_name(row['agreement']).id
          else
            entrant_application.budget_agr = competitive_groups.find_by_name(row['agreement']).id
          end
        end
      end
      entrant_application.contracts = [] if row['contract_lech'] || row['contract_ped'] || row['contract_stomat']
      entrant_application.contracts << competitive_groups.find_by_name('Лечебное дело. Внебюджет.').id if row['contract_lech']
      entrant_application.contracts << competitive_groups.find_by_name('Педиатрия. Внебюджет.').id if row['contract_ped']
      entrant_application.contracts << competitive_groups.find_by_name('Стоматология. Внебюджет.').id if row['contract_stomat']
      if entrant_application.save!
        IdentityDocument.import_from_row(row, entrant_application) if row.keys.include? 'identity_document_type'
        EducationDocument.import_from_row(row, entrant_application) if row.keys.include? 'education_document_type'
        BenefitDocument.import_from_row(row, entrant_application) if row.keys.include? 'benefit_document_type_id'
        OlympicDocument.import_from_row(row, entrant_application) if row.keys.include? 'olympic_id'
        Mark.import_from_row(row, entrant_application) if row.keys.include?('chemistry') || row.keys.include?('biology') || row.keys.include?('russian') || row.keys.include?('test_result')
        Achievement.import_from_row(row, entrant_application)
        case true
        when campaign.education_levels.include?(5)
          unless row.keys.include?('benefit_document_type_id') || row.keys.include?('alt_entrant_last_name') || row.keys.include?('olympic_id') || row.keys.include?('enrolled') || row.keys.include?('contract_lech')
            entrant_application.competitive_groups = [] unless row.keys.include?('enrolled') || row.keys.include?('chemistry') || row.keys.include?('biology') || row.keys.include?('russian')
            competitive_groups.each do |competitive_group|
              entrant_application.competitive_groups << competitive_group if row[competitive_group.name]
            end
            if row['target_organization_id_lech'] || row['target_organization_id_ped'] || row['target_organization_id_stomat']
            entrant_application.target_contracts.destroy_all
              target_compeitive_group_names = ['Лечебное дело. Целевые места.', 'Педиатрия. Целевые места.', 'Стоматология. Целевые места.']
              [row['target_organization_id_lech'], row['target_organization_id_ped'], row['target_organization_id_stomat']].each_with_index do |target_organization_ids, index|
                if target_organization_ids
                  target_organization_ids.split(',').each do |target_organization_id|
                    entrant_application.target_contracts.create(target_organization_id: target_organization_id, competitive_group_id: competitive_groups.find_by_name(target_compeitive_group_names[index]).id)
                  end
                end
              end
            end
          end
        when campaign.education_levels.include?(18)
          if row['spec1']
            entrant_application.competitive_groups = [] unless row.keys.include?('enrolled')
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 14) if row['budg1']
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 15) if row['paid1']
            if row['target1']
              entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 16)
              entrant_application.target_contracts.destroy_all
              entrant_application.target_contracts.create(target_organization_id: row['target1'], competitive_group_id: competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 16).first.id)
            end
          end
          if row['spec2']
            entrant_application.competitive_groups = [] unless row.keys.include?('enrolled')
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 14) if row['budg2']
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 15) if row['paid2']
            if row['target2']
              entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 16) 
              entrant_application.target_contracts.destroy_all
              entrant_application.target_contracts.create(target_organization_id: row['target2'], competitive_group_id: competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 16).first.id)
            end
          end
        end
      end
      entrant_application.touch
    end
  end
  
  def self.ege_to_txt(entrant_applications)
    ege_to_txt = ""
    entrant_applications.each do |entrant_application|
      entrant_application.identity_documents.each do |identity_document|
        if identity_document.alt_entrant_last_name &&  !identity_document.alt_entrant_last_name.empty?
          ege_to_txt += "#{[identity_document.alt_entrant_last_name, identity_document.alt_entrant_first_name, identity_document.alt_entrant_middle_name].join('%')}%#{[identity_document.identity_document_series, identity_document.identity_document_number].join('%')}\r\n"
        else
          ege_to_txt += "#{[entrant_application.entrant_last_name, entrant_application.entrant_first_name, entrant_application.entrant_middle_name].join('%')}%#{[identity_document.identity_document_series, identity_document.identity_document_number].join('%')}\r\n"
        end
      end
    end
    ege_to_txt.encode("cp1251")
  end
  
  def self.errors(campaign)
    errors = {}
    applications = campaign.entrant_applications.order(:application_number).where(status_id: [2, 4]).where.not(application_number: nil)
    errors[:dups_numbers] = find_dups_numbers(applications)
    errors[:lost_numbers] = find_lost_numbers(applications, campaign)
    errors[:dups_entrants] = find_dups_entrants(applications)
#     target_competition_entrants_array = applications.joins(:competitive_groups).where(competitive_groups: {education_source_id: 16}).uniq
#     errors[:empty_target_entrants] = find_empty_target_entrants(target_competition_entrants_array, applications.joins(:target_organizations))
#     errors[:not_original_target_entrants] = find_not_original_target_entrants(target_competition_entrants_array, applications.joins(:education_document).where.not(education_documents: {original_received_date: nil}))
#     errors[:not_agreed_target_entrants] = find_not_agreed_entrants(applications)
    errors[:expired_passports] = find_expired_passports(applications.where.not(birth_date: nil))
    errors[:empty_achievements] = find_empty_achievements(applications)
    errors[:elders] = find_elders(applications)
    errors[:empty_marks] = find_empty_marks(applications)
    errors
  end
  
  def self.find_empty_marks(applications)
    applications.joins(:marks).where(status_id: 4, marks: {value: 0, form: 'ЕГЭ'}).uniq
  end
  
  def self.find_elders(applications)
    applications.select{|a| Time.now.to_date > a.birth_date + 20.years}.select{|a| a.identity_documents.count == 1 && a.marks.map(&:form).count('Экзамен') != 3}
  end
  
  def self.find_empty_achievements(applications)
    applications.joins(:achievements).where(status_id: 4, achievements: {value: 0}).uniq
  end
  
  def self.find_dups_numbers(applications)
    find_dups_numbers = []
    h = applications.select(:application_number).group(:application_number).count.select{|k, v| v > 1}
    h.each{|k, v| find_dups_numbers << applications.find_by_application_number(k)}
    find_dups_numbers
  end
  
  def self.find_lost_numbers(applications, campaign)
    application_numbers = applications.map(&:application_number)
    revoked_application_numbers = EntrantApplication.where(status_id: 6, campaign_id: campaign).map(&:application_number)
    max_number = application_numbers.max
    max_number ? (1..max_number).to_a - application_numbers - revoked_application_numbers : []
  end
  
  def self.find_dups_entrants(applications)
    IdentityDocument.joins(:entrant_application).where(entrant_applications: {id: applications}).group_by{|i| i.sn}.select{|k, v| v.size > 1}.map{|k, v| applications.joins(:identity_documents).where(identity_documents: {id: v})}.flatten.uniq
  end
  
  def self.find_empty_target_entrants(target_competition_entrants_array, target_organizations_array)
    (target_competition_entrants_array - target_organizations_array).sort
  end
                                                                                         
  def self.find_not_original_target_entrants(target_competition_entrants_array, original_received_array)
    (target_competition_entrants_array - original_received_array).sort
  end
  
  def self.find_not_agreed_entrants(applications)
   applications.joins(:competitive_groups).where(competitive_groups: {education_source_id: 16}).select{|a| a.competitive_groups.find_by_education_source_id(16).id != a.budget_agr}.uniq.sort_by(&:application_number)
  end

  def self.find_expired_passports(applications)
    applications.select{|a| Time.now.to_date > a.birth_date + 20.years}.select{|a| a.identity_documents.where.not(identity_document_date: nil).order(identity_document_date: :asc).last.identity_document_date < a.birth_date + 20.years}
  end
  
  def self.admission_volume_hash(campaign)
    admission_volume_hash = {}
    campaign.competitive_groups.order(:name).includes(:competitive_group_item).sort_by{|cg| cg.edu_programs.map(&:name)}.group_by(&:direction_id).each do |k, v|
      admission_volume_hash[k] = {}
      v.each do |competitive_group|
        admission_volume_hash[k][competitive_group] = [competitive_group.competitive_group_item.number_budget_o, 
        competitive_group.competitive_group_item.number_budget_oz, 
        competitive_group.competitive_group_item.number_budget_z,
        competitive_group.competitive_group_item.number_paid_o,
        competitive_group.competitive_group_item.number_paid_oz,
        competitive_group.competitive_group_item.number_paid_z,
        competitive_group.competitive_group_item.number_quota_o, 
        competitive_group.competitive_group_item.number_quota_oz, 
        competitive_group.competitive_group_item.number_quota_z,
        competitive_group.competitive_group_item.number_target_o, 
        competitive_group.competitive_group_item.number_target_oz, 
        competitive_group.competitive_group_item.number_target_z].sum
      end
    end
    admission_volume_hash
  end
  

  def self.entrant_applications_hash(campaign)
    entrant_applications = campaign.entrant_applications.select([:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :status_id, :benefit, :budget_agr, :paid_agr, :enrolled, :enrolled_date, :exeptioned, :snils, :birth_date, :registration_date, :gender_id, :nationality_type_id, :contracts]).order(:application_number).includes(:achievements, :education_document, :competitive_groups, :benefit_documents, :olympic_documents, :target_contracts)
    
    entrance_test_items = campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    
    marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id)
    mark_values = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.value].inject(:merge)}}}.inject(:merge)
    
    mark_forms = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.form].inject(:merge)}}}.inject(:merge)
    
    achievements = Achievement.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id)
    achievement_values = achievements.map{|a, achs| {a => achs.sort_by(&:institution_achievement_id).map(&:value)}}.inject(:merge)
    
    entrant_applications_hash = {}
    entrant_applications.each do |entrant_application|
      entrant_applications_hash[entrant_application] = {}
      entrant_applications_hash[entrant_application][:competitive_groups] = entrant_application.competitive_groups.map(&:id)
      entrant_applications_hash[entrant_application][:mark_values] = []
      entrant_applications_hash[entrant_application][:mark_forms] = []
      entrance_test_items.each do |entrance_test_item|
        mark_value = mark_values[entrant_application.id].inject(:merge)[entrance_test_item.subject_id]
        mark_form = mark_forms[entrant_application.id].inject(:merge)[entrance_test_item.subject_id]
        entrant_applications_hash[entrant_application][:mark_values] << mark_value
        entrant_applications_hash[entrant_application][:mark_forms] << mark_form
      end
      entrant_applications_hash[entrant_application][:summa] = entrant_applications_hash[entrant_application][:mark_values].size == entrance_test_items.size ? entrant_applications_hash[entrant_application][:mark_values].compact.sum : 0
      entrant_applications_hash[entrant_application][:achievements] = achievement_values[entrant_application.id]
      achievements_sum = entrant_applications_hash[entrant_application][:achievements] ? entrant_applications_hash[entrant_application][:achievements].sum : 0
      achievements_limit = 10.to_f if campaign.education_levels.include?(5)
      entrant_applications_hash[entrant_application][:achievements_sum] = achievements_limit ? (achievements_sum > achievements_limit ? achievements_limit : achievements_sum) : achievements_sum
      entrant_applications_hash[entrant_application][:summa] > 0 ? entrant_applications_hash[entrant_application][:full_summa] = [entrant_applications_hash[entrant_application][:summa], entrant_applications_hash[entrant_application][:achievements_sum]].sum : entrant_applications_hash[entrant_application][:full_summa] = 0
      entrant_applications_hash[entrant_application][:original_received] = true if entrant_application.education_document.original_received_date
      entrant_applications_hash[entrant_application][:benefit] = entrant_application.benefit ? 1 : 0
      entrant_applications_hash[entrant_application][:examless] = true if entrant_application.olympic_documents.map(&:benefit_type_id).include?(1)
    end
    entrant_applications_hash
  end

  def self.ord_export(applications)
    oid = '1.2.643.5.1.13.13.12.4.37.21'
    headers = [
      'snils',
      'surname',
      'name',
      'patronymic',
      'oid',
      'compaignId',
      'dateOfBirth',
      'citizenship',
      'specialty',
      'financingType',
      'applicationDate',
      'targetReception',
      'testResultType',
      'testResultOrganization',
      'testResultYear'
    ]

    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      applications.each do |application|
        application.competitive_groups.each do |competitive_group|
          citizenship = application.nationality_type_id == 1 ? 643 : ''
          test_result_type = application.marks.map(&:form).include?('Аккредитация') ? 'аккредитация' : 'ординатура'
          test_result_year = application.marks.map(&:year).first
          row = [
            application.snils.strip,
            application.entrant_last_name.strip,
            application.entrant_first_name.strip,
            application.entrant_middle_name.strip,
            oid,
            3,
            application.birth_date.strftime("%d.%m.%Y"),
            citizenship,
            competitive_group.edu_programs.last.code,
            (competitive_group.education_source_id == 15 ? 'договор' : 'бюджет'),
            application.registration_date.strftime("%d.%m.%Y"),
            (competitive_group.education_source_id == 16 ? 'да' : 'нет'),
            test_result_type,
            application.marks.map(&:organization_uid).first.strip,
            test_result_year
            ]
          csv << row
        end
      end
    end
  end
  
  def self.ord_return_export(applications)
    oid = '1.2.643.5.1.13.13.12.4.37.21'
    headers = [
      'snils',
      'oid',
      'compaignId',
      'dateOfBirth',
      'specialty',
      'financingType',
      'applicationDate',
      'targetReception',
      'initiative'
    ]

    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      applications.each do |application|
        application.competitive_groups.each do |competitive_group|
          row = [
            application.snils,
            oid,
            3,
            application.birth_date.strftime("%d.%m.%Y"),
            competitive_group.edu_programs.last.code,
            (competitive_group.education_source_id == 15 ? 'договор' : 'бюджет'),
            application.registration_date.strftime("%d.%m.%Y"),
            (competitive_group.education_source_id == 16 ? 'да' : 'нет'),
            1
            ]
          csv << row
        end
      end
    end
  end
  
  def self.ord_marks_request(applications)
    oid = '1.2.643.5.1.13.13.12.4.37.21'
    headers = [
      'snils',
      'oid',
      'dateOfBirth',
      'testResultType',
      'testResultYear',
      'testResultOrganization',
      'specialty'
    ]

    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      applications.each do |application|
        test_result_type = application.marks.map(&:form).include?('Аккредитация') ? 'аккредитация' : 'ординатура'
        test_result_year = application.marks.map(&:year).first
        row = [
          application.snils.strip,
          oid,
          application.birth_date.strftime("%d.%m.%Y"),
          test_result_type,
          test_result_year,
          application.marks.map(&:organization_uid).first.strip,
          application.education_document.education_speciality_code
          ]
        csv << row
      end
    end
  end
  
  def self.ord_access_request(applications)
    oid = '1.2.643.5.1.13.13.12.4.37.21'
    headers = [
      'snils',
      'oid',
      'dateOfBirth',
      'specialty',
      'date',
      'attemptType',
      'retryReason'
    ]

    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      applications.each do |application|
        row = [
          application.snils,
          oid,
          application.birth_date.strftime("%d.%m.%Y"),
          application.education_document.education_speciality_code,
          Time.now.to_date == '2020-08-03'.to_date ? '06.08.2020' : '07.08.2020',
          1
          ]
        csv << row
      end
    end
  end
  
  def self.ord_result_export(applications)
    oid = '1.2.643.5.1.13.13.12.4.37.21'
    headers = [
      'snils',
      'oid',
      'compaignId',
      'dateOfBirth',
      'specialty',
      'financingType',
      'targetReception',
      'applicationDate',
      'amountScore',
      'testResult',
      'individualAchievements',
      'applicationStatus',
      'admissionOrderNumber',
      'admissionOrderDate',
      'regulationsParagraph',
      'diplomaIssueDate',
      'diplomaSpecialty'
    ]
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << headers
      applications.select{|application, values| application.nationality_type_id == 1 && (application.status_id == 4 || application.status_id == 6)}.each do |application, values|
        application.competitive_groups.each do |competitive_group|
          status = case application.status_id
                    when 6
                      3
                    when 4
                      application.enrolled && application.enrolled == competitive_group.id ? 1 : 2
                    end
          order_number = case application.enrolled_date
                          when Date.new(2020, 8, 12)
                            '97-ипо'
                          when Date.new(2020, 8, 14)
                            '98-ипо'
                          when Date.new(2020, 8, 17)
                            '99-ипо'
                          end
                          
          achievements_array = []
          application.achievements.sort_by(&:institution_achievement_id).each do |achievement|
            case achievement.institution_achievement_id
            when 38
              achievements_array << 'a'
            when 39
              achievements_array << 'б'
            when 40
              achievements_array << 'в'
            when 41
              case achievement.value
              when 15
                achievements_array << 'г1'
              when 100
                achievements_array << 'г2'
              when 150
                achievements_array << 'г3'
              end
            when 42
              achievements_array << 'д'
            when 43
              achievements_array << 'е'
            when 44
              achievements_array << 'ж'
            when 45
              achievements_array << '21а'
            when 46
              achievements_array << '21б'
            when 47
              achievements_array << 'з'
            end
          end
          achievements = achievements_array.join(',')
          test_result = values[:mark_values].sum.round() == 0 ? application.marks.sum(:value).round() : values[:mark_values].sum.round()
          achievements_sum = values[:achievements] ? values[:achievements].sum : 0
          full_summa = values[:full_summa].round() == 0 ? [test_result, achievements_sum].sum : values[:full_summa].round()
          row = [
            application.snils,
            oid,
            3,
            application.birth_date.strftime("%d.%m.%Y"),
            competitive_group.edu_programs.last.code,
            (competitive_group.education_source_id == 15 ? 'договор' : 'бюджет'),
            (competitive_group.education_source_id == 16 ? 'да' : 'нет'),
            application.registration_date.strftime("%d.%m.%Y"),
            full_summa,
            (test_result if test_result > 0),
            (achievements if achievements_sum > 0),
            status,
            (order_number if status == 1),
            (application.enrolled_date.strftime("%d.%m.%Y") if status == 1),
            nil,
            application.education_document.education_document_date.strftime("%d.%m.%Y"),
            application.education_document.education_speciality_code
            ]
          csv << row
        end
      end
    end
  end
  
  def self.target_report(applications)
    target_competitive_groups = CompetitiveGroup.where(education_source_id: 16).map(&:id)
    target_enrolled_applications = applications.select{|application, values| target_competitive_groups.include?(application.enrolled)}
    xml = ::Builder::XmlMarkup.new
    xml.root(id: 2277) do |root|
      n = 342
      target_enrolled_applications.each do |application, values|
        n += 1
        case CompetitiveGroup.find(application.enrolled).direction_id
        when 17509
          spec = 3073
          duration = 6
        when 17353
          spec = 3074
          duration = 6
        when 17247
          spec = 3075
          duration = 5
        end
        year_start = application.campaign.year_start
        p5_5 = application.target_organization.target_organization_name
        case application.target_organization_id
        when 2
          p5_8 = 55908
          p5_9 = 0
          p5_10 = 1
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с постановлением администрации Владимирской области от 07.11.2014 № 1143'
          p5_15 = 12000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 2
        when 3
          p5_8 = 60696
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'ежемесячная денежная выплата в соответствии с законом Вологодской области от 6 мая 2013 года № 3035-ОЗ О мерах социальной поддержки, направленных на кадровое обеспечение системы здравоохранения области'
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 2
        when 4
          p5_8 = 74808
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'обеспечить предоставление гражданину в период его обучения меры социальной поддержки в сооответствии с Муниципальными программами (подпрограммами), принятыми в целях привлечения медицинских кадров для работы в учреждениях здравоохранения Ивановской области'
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 0
        when 5
          p5_8 = 94800
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с действующим законодательством Костромской области, устанавливающим социальные гарантии для граждан, обучающихся в медицинских ВУЗах в рамках целевой контрактной подготовки от Костромской области'
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 3
        when 6
          p5_8 = 111446
          p5_9 = 0
          p5_10 = 2
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 16080
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 2
        when 8
          p5_8 = 197660
          p5_9 = 0
          p5_10 = 3
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 36000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 2
        when 9
          p5_8 = 74808
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'выплата стипендии в размере, определяемом приказом руководителя Организации, принимаемым в установленном порядке до начала учебного года, при условии успешного освоения учебных дисциплин согласно учебному плану, подтвержденного результатами промежуточной аттестации со средним баллом не ниже 4,0; компенсация расходов, понесенных на обучение, повышение уровня знаний, совершенствование профессиональных компетенций'
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 3
        when 42
          p5_8 = 74808
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 0
        when 43
          p5_8 = 215418
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 0
          zak_type_1 = 0
          zak_type_2 = 0
          p5_32 = 0
        when 20
          p5_8 = 56483
          p5_9 = 1
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 6000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 27
          p5_32 = 2
        when 22
          p5_8 = 56978
          p5_9 = 0
          p5_10 = 1
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с постановлением администрации Владимирской области от 07.11.2014 № 1143'
          p5_15 = 6000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 29
          p5_32 = 2
        when 23
          p5_8 = 57448
          p5_9 = 0
          p5_10 = 0
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'поощрить денежной выплатой в размере 1000 рублей в случае получения диплома с отличием'
          p5_15 = 0
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 30
          p5_32 = 2
        when 24
          p5_8 = 56727
          p5_9 = 0
          p5_10 = 1
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = 'предоставить гражданину в период его обучения меры социальной поддержки в соответствии с муниципальной программой'
          p5_15 = 10000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 31
          p5_32 = 2
        when 25
          p5_8 = 57582
          p5_9 = 0
          p5_10 = 0
          p5_11 = 1
          p5_12 = 0
          p5_13 = 3
          p5_14 = ''
          p5_15 = 145000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 32
          p5_32 = 0
        when 26
          p5_8 = 58200
          p5_9 = 0
          p5_10 = 1
          p5_11 = 0
          p5_12 = 0
          p5_13 = 0
          p5_14 = ''
          p5_15 = 4000
          p5_16 = p5_5
          p5_19 = p5_8
          zak_type = 2
          zak_type_1 = 0
          zak_type_2 = 33
          p5_32 = 2
        end
        ege = []
        values[:mark_forms].each_with_index{|val, index| ege << values[:mark_values][index] if val == 'ЕГЭ'}
        ege.size == 0 ? values[:mean] = nil : values[:mean] = ege.sum.to_f/ege.size
        
        root.lines(nom: n) do |lines|
          lines.oo 2277
          lines.spec spec
          lines.fo 1
          lines.if 1
          lines.up 3
          lines.id_kladr 74809
          lines.fio
          lines.p5_1 [year_start, "%04d" % application.application_number].join('-')
          lines.p5_2 application.gender_id
          lines.p5_3 year_start
          lines.p5_4 year_start + duration
          lines.p5_5 p5_5
          lines.p5_8 p5_8
          lines.p5_9 p5_9
          lines.p5_10 p5_10
          lines.p5_11 p5_11
          lines.p5_12 p5_12
          lines.p5_13 p5_13
          lines.p5_14 p5_14
          lines.p5_15 p5_15
          lines.p5_16 p5_16
          lines.p5_19 p5_19
          lines.zak_type zak_type
          lines.zak_type_1 zak_type_1
          lines.zak_type_2 zak_type_2
          lines.p5_22 0
          lines.p5_23 0
          lines.p5_24 0
          lines.p5_25 0
          lines.p5_26 0
          lines.p5_27 0
          lines.p5_28 0
          lines.p5_29 
          lines.p5_30 year_start
          lines.p5_31 values[:mean]
          lines.p5_32 p5_32
          lines.p5_33 0
          lines.p5_21_1
          lines.p5_21_2
          lines.p5_21_3
          lines.p5_21_4
          lines.p5_21_5
          lines.p5_21_6
          lines.p5_21_7
          lines.p5_21_8
          lines.p5_21_9
          lines.p5_21_10
          lines.p5_21_11
          lines.p5_21_12
          lines.p5_21_13
          lines.p5_21_14
          lines.prim1
        end
      end
    end
  end
  
  def generate_templates
    countries = Dictionary.find_by_name('Страна').items
    identity_documents_list = Dictionary.find_by_name('Тип документа, удостоверяющего личность').items
    benefit_types = Dictionary.find_by_name('Вид льготы').items
    document_types = Dictionary.find_by_name('Тип документа').items
    title = "Заявление о приеме в ИвГМА № #{application_number}"
    tempfile = "#{[Rails.root, 'storage', 'tmp', title].join("/")}.pdf"
    pdf = Prawn::Document.new(page_size: "A4", :info => {
      :Title => title,
      :Author => "Vladimir Markovnin",
      :Subject => "Прием ИвГМА",
      :Creator => "ИвГМА",
      :Producer => "Prawn",
      :CreationDate => Time.now }
      )
    pdf.font_families.update("Ubuntu" => {
      :normal => "vendor/fonts/Ubuntu-R.ttf",
      :italic => "vendor/fonts/Ubuntu-RI.ttf",
      :bold => "vendor/fonts/Ubuntu-B.ttf"
      })
    pdf.font "Ubuntu"
    pdf.text title, style: :bold, :size => 14, align: :center
    pdf.move_down 4
    pdf.text "Ректору ФГБОУ ВО ИвГМА Минздрава России", size: 10, align: :right
    pdf.move_down 4
    pdf.text "д.м.н., проф. Е. В. Борзову", size: 10, align: :right
    pdf.move_down 4
    pdf.move_down 4
    case campaign.campaign_type_id
    when 1
      pdf.text "Я, #{fio}, прошу допустить меня к участию в конкурсе в ФГБОУ ВО ИвГМА Минздрава России на программы специалитета", size: 10
    when 4
      pdf.text "Я, #{fio}, прошу допустить меня к участию в конкурсе в ФГБОУ ВО ИвГМА Минздрава России на программы ординатуры", size: 10
    end
    pdf.move_down 4
    pdf.move_down 4
    pdf.text "Персональные данные", size: 12
    pdf.move_down 4
    pdf.text "Дата рождения: #{birth_date.strftime("%d.%m.%Y")}", size: 10
    pdf.move_down 4
    pdf.text "Гражданство: #{countries.select{|item| item['id'] == nationality_type_id}[0]['name']}", size: 10
    pdf.move_down 4
    if address
      pdf.text "Адрес проживания: #{address}", size: 10
      pdf.move_down 4
    end
    if email && campaign.campaign_type_id == 4
      pdf.text "Адрес электронной почты: #{email}", size: 10
      pdf.move_down 4
    end
    pdf.move_down 4
    pdf.text "Документ удостоверяющий личность", size: 12
    pdf.move_down 4
    identity_document = identity_documents.order(identity_document_date: :asc).last
    pdf.text "#{identity_documents_list.select{|item| item['id'] == identity_document.identity_document_type}[0]['name']}: #{identity_document.identity_document_data}", size: 10
    pdf.move_down 4
    pdf.move_down 4
    pdf.text "Документ об образовании", size: 12
    pdf.move_down 4
    pdf.text "#{education_document.education_document_data}", size: 10
    pdf.move_down 4
    pdf.move_down 4
    if campaign.campaign_type_id == 4
      other_documents.where(name: 'Свидетельство об аккредитации специалиста').each do |other_document|
        pdf.text "#{other_document.other_document_data}", size: 12
        pdf.move_down 4
        pdf.move_down 4
      end
      other_documents.where(name: 'Выписка из итогового протокола заседания аккредитационной комиссии').each do |other_document|
        pdf.text "#{other_document.other_document_data}", size: 12
        pdf.move_down 4
        pdf.move_down 4
      end
      pdf.text "Номер СНИЛС #{snils}", size: 12
      pdf.move_down 4
      pdf.move_down 4
    end
    pdf.text "Прошу рассмотреть мои документы для участия в следующих конкурсах:", size: 12
    pdf.move_down 4
    competitive_groups.each do |competitive_group|
      pdf.text "- #{competitive_group.name}", size: 10
      pdf.move_down 4
      pdf.move_down 4
    end
    if olympionic || benefit
      pdf.text "Имею особые права:", size: 12
      pdf.move_down 4
      olympic_documents.each do |olympic_document|
        pdf.text "Имею право на #{benefit_types.select{|item| item['id'] == olympic_document.benefit_type_id}[0]['name']}", size: 10
        pdf.move_down 4
        pdf.text "Реквизиты документа, дающего особое право: #{document_types.select{|item| item['id'] == olympic_document.olympic_document_type_id}[0]['name']} #{olympic_document.olympic_document_data}", size: 10
        pdf.move_down 4
      end
      benefit_documents.each do |benefit_document|
        pdf.text "Имею право на #{'прием' if benefit_document.benefit_type_id == 4} #{benefit_types.select{|item| item['id'] == benefit_document.benefit_type_id}[0]['name']}", size: 10
        pdf.move_down 4
        pdf.text "Реквизиты документа, дающего особое право: #{document_types.select{|item| item['id'] == benefit_document.benefit_document_type_id}[0]['name']} #{benefit_document.benefit_document_data}", size: 10
        pdf.move_down 4
      end
    end
    pdf.text "Для участия в конкурсе выбираю следующие формы вступительных испытаний:", size: 12
    pdf.move_down 4
    marks.each do |mark|
      pdf.text "#{mark.subject.subject_name} - #{mark.form}", size: 10
      pdf.move_down 4
    end
    if special_entrant
      pdf.text "Нуждаюсь в необходимости создания особых условиях при проведении вступительных испытаний в связи с ограниченными возможностями здоровья, а именно:", size: 10
      pdf.move_down 4
      pdf.text "#{special_conditions}", size: 10
      pdf.move_down 4
      pdf.move_down 4
    end
    unless achievements.empty?
      pdf.text "Имею следующие индивидуальные достижения", size: 12
      pdf.move_down 4
      achievements.each do |achievement|
        pdf.text "- #{achievement.institution_achievement.name}", size: 10
        pdf.move_down 4
        pdf.move_down 4
      end
    end
    if need_hostel
      pdf.text "Нуждаюсь в предоставлении места в общежитии на период обучения", size: 10
      pdf.move_down 4
    end
    pdf.move_down 4
    case campaign.campaign_type_id
    when 1
      pdf.text "Подтверждаю, что я ознакомлен с  с копией лицензии на осуществление образовательной деятельности (с приложением); с копией свидетельства о государственной аккредитации (с приложением) или с информацией об отсутствии указанного свидетельства; с информацией о предоставляемых поступающим особых правах и преимуществах; с датами завершения приема заявлений о согласии на зачисление; с правилами приема, в том числе с правилами подачи апелляции по результатам вступительных испытаний, проводимых Академией самостоятельно", size: 10
    when 4
      pdf.text "Подтверждаю, что я ознакомлен с  с копией лицензии на осуществление образовательной деятельности (с приложением); с копией свидетельства о государственной аккредитации (с приложением) или с информацией об отсутствии указанного свидетельства; с датами завершения приема заявлений о согласии на зачисление; с правилами приема, в том числе с правилами подачи апелляции по результатам вступительного испытания", size: 10
    end
    pdf.move_down 4
    pdf.text "Подпись ___________________", size: 10, align: :right
    pdf.move_down 4
    pdf.text "Согласен на обработку персональных данных", size: 10
    pdf.move_down 4
    pdf.text "Подпись ___________________", size: 10, align: :right
    pdf.move_down 4
    pdf.text "Ознакомлен с информацией о необходимости указания в заявлении о приеме достоверных сведений и представления подлинных документов", size: 10
    pdf.move_down 4
    pdf.text "Подпись ___________________", size: 10, align: :right
    pdf.move_down 4
    case campaign.campaign_type_id
    when 1
      unless (competitive_groups.map(&:education_source_id) - [15]).empty? || education_document.education_document_type == 'HighEduDiplomaDocument'
        pdf.text "Потверждаю отсутствие у меня диплома бакалавра, диплома специалиста, диплома магистра", size: 10
        pdf.move_down 4
        pdf.text "Подпись ___________________", size: 10, align: :right
        pdf.move_down 4
      end
    when 4
      unless (competitive_groups.map(&:education_source_id) - [15]).empty?
        pdf.text "Потверждаю отсутствие у меня диплома об окончании ординатуры или диплома об окончании интернатуры", size: 10
        pdf.move_down 4
        pdf.text "Подпись ___________________", size: 10, align: :right
        pdf.move_down 4
      end
    end
    case campaign.campaign_type_id
    when 1
      pdf.text "Подтверждаю, что одновременно подаю заявления о приеме не более чем в 5 организаций высшего образования, включая ИвГМА", size: 10
      pdf.move_down 4
      pdf.text "Подпись ___________________", size: 10, align: :right
      pdf.move_down 4
      if olympic_documents.map(&:benefit_type_id).include?(1)
        pdf.text "Подтверждаю, что подаю заявления о приеме на основании соответствующего особого права только в ИвГМА и только на одну образовательную программу", size: 10
        pdf.move_down 4
        pdf.text "Подпись ___________________", size: 10, align: :right
        pdf.move_down 4
      end
    when 4
      pdf.text "Обязуюсь представить заявление о согласии на зачисление не позднее дня завершения приема заявлений о согласии на зачисление", size: 10
      pdf.move_down 4
      pdf.text "Подпись ___________________", size: 10, align: :right
      pdf.move_down 4
    end
    
    if campaign.campaign_type_id == 4 && marks.map(&:form).include?('Аккредитация')
      pdf.start_new_page
      pdf.text "Ректору ФГБОУ ВО ИвГМА Минздрава России", align: :right, size: 10
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right, size: 10
      pdf.move_down 6
      pdf.move_down 6
      pdf.text "Я, #{fio}, прошу учесть в качестве вступительного испытания результаты тестирования в рамках процедуры аккредитации, пройденной в ______ году на базе __________________________________________, по специальности ________________________", size: 10
      pdf.move_down 6  
      pdf.move_down 6  
      pdf.text "Подпись ___________________", size: 10, align: :right
    end

    pdf.render_file tempfile
    
    attachment = attachments.where(document_type: 'entrant_application', document_id: id, template: true).first || Attachment.new
    attachment.entrant_application_id = id
    attachment.document_type = 'entrant_application'
    attachment.document_id = id
    attachment.filename = "#{title}.pdf"
    attachment.mime_type = 'application/pdf'
    attachment.merged = false
    attachment.template = true
    md5 = ::Digest::MD5.file(tempfile).hexdigest
    attachment.data_hash = md5
    path = attachment.data_hash[0..2].split('').join('/')
    if attachment.save
      %x(mkdir -p #{Rails.root.join('storage', path)})
      file_path = Rails.root.join('storage', path, attachment.data_hash)
      %x(mv "#{tempfile}" "#{file_path}")
      %x(touch "#{file_path}")
    end
    
    competitive_groups.each do |competitive_group|
      title = "Заявление о согласии на зачисление в ИвГМА"
      tempfile = "#{[Rails.root, 'storage', 'tmp', title].join("/")}.pdf"
      pdf = Prawn::Document.new(page_size: "A4", :info => {
        :Title => title,
        :Author => "Vladimir Markovnin",
        :Subject => "Прием ИвГМА",
        :Creator => "ИвГМА",
        :Producer => "Prawn",
        :CreationDate => Time.now }
        )
      pdf.font_families.update("Ubuntu" => {
        :normal => "vendor/fonts/Ubuntu-R.ttf",
        :italic => "vendor/fonts/Ubuntu-RI.ttf",
        :bold => "vendor/fonts/Ubuntu-B.ttf"
        })
      pdf.font "Ubuntu"
      pdf.text title, style: :bold, :size => 14, align: :center
      pdf.move_down 6
      pdf.text "Ректору ФГБОУ ВО ИвГМА Минздрава России", align: :right
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right
      pdf.move_down 6
      pdf.move_down 6
      case campaign.campaign_type_id
      when 1
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), прошу зачислить меня на обучение по образовательной программе специалитета в рамках конкурса #{competitive_group.name}"
      when 4
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), прошу зачислить меня на обучение по образовательной программе ординатуры в рамках конкурса #{competitive_group.name}"
      end
      pdf.move_down 6
      pdf.text "Обязуюсь:"
      pdf.move_down 6
      pdf.move_down 6
      unless competitive_group.education_source_id == 15
        pdf.text "в течение первого года обучения представить в ФГБОУ ВО ИвГМА Минздрава России оригинал документа, удостоверяющего образование соответствующего уровня, необходимого для зачисления"
      else
        pdf.text "в течение первого года обучения представить в ФГБОУ ВО ИвГМА Минздрава России оригинал документа (или заверенную копию), удостоверяющего образование соответствующего уровня, необходимого для зачисления"
      end
      pdf.move_down 6
      pdf.text "Подпись ___________________"
      pdf.move_down 6
      if campaign.campaign_type_id == 1
        pdf.text "пройти обязательные предварительные медицинские осмотры (обследования) в порядке, установленном при заключении трудового договора или служебного контракта по соответствующей должности или специальности, утвержденном постановлением Правительства Российской Федерации от 14 августа 2013 г. No 697"
        pdf.move_down 6
        pdf.text "Подпись ___________________"
        pdf.move_down 6
      end
      pdf.text "Подтверждаю, что у меня отсутствуют действительные (не отозванные) заявления о согласии на зачисление на обучение по программам высшего образования данного уровня на места в рамках контрольных цифр, в том числе поданные в другие организации"
      pdf.move_down 6
      pdf.text "Подпись ___________________"
      pdf.move_down 6
      pdf.move_down 6
      pdf.text "Подпись ___________________", align: :right
      if campaign.campaign_type_id == 1
        pdf.move_down 12
        pdf.text "ОБРАТИТЕ ВНИМАНИЕ!!! Единовременно можно подать только ОДНО заявление о согласии на зачисление (только по ОДНОМУ конкурсу). Если Вы подадите одновременно несколько заявлений о согласии, это будет являться нарушением правил приема, и Вы не будете зачислены в нашу академию. При необходимости Вы сможете отозвать заявление о согласии (написав и прикрепив заявление об отзыве согласия) и подать согласие на другой конкурс. На бюджетные конкурсы можно последовательно подать лишь ДВА согласия, на внебюджетные - неограниченное количество раз."
      end
      
      pdf.render_file tempfile
    
      attachment = attachments.where(document_type: 'consent_application', document_id: competitive_group.id, template: true).first || Attachment.new
      attachment.entrant_application_id = id
      attachment.document_type = 'consent_application'
      attachment.document_id = competitive_group.id
      attachment.filename = "#{title}.pdf"
      attachment.mime_type = 'application/pdf'
      attachment.merged = false
      attachment.template = true
      md5 = ::Digest::MD5.file(tempfile).hexdigest
      attachment.data_hash = md5
      path = attachment.data_hash[0..2].split('').join('/')
      if attachment.save
        %x(mkdir -p #{Rails.root.join('storage', path)})
        file_path = Rails.root.join('storage', path, attachment.data_hash)
        %x(mv "#{tempfile}" "#{file_path}")
        %x(touch "#{file_path}")
      end
      
      title = "Заявление об отказе от зачисления в ИвГМА"
      tempfile = "#{[Rails.root, 'storage', 'tmp', title].join("/")}.pdf"
      pdf = Prawn::Document.new(page_size: "A5", page_layout: :landscape, :info => {
        :Title => title,
        :Author => "Vladimir Markovnin",
        :Subject => "Прием ИвГМА",
        :Creator => "ИвГМА",
        :Producer => "Prawn",
        :CreationDate => Time.now }
        )
      pdf.font_families.update("Ubuntu" => {
        :normal => "vendor/fonts/Ubuntu-R.ttf",
        :italic => "vendor/fonts/Ubuntu-RI.ttf",
        :bold => "vendor/fonts/Ubuntu-B.ttf"
        })
      pdf.font "Ubuntu"
      pdf.text title, style: :bold, :size => 14, align: :center
      pdf.move_down 6
      pdf.text "Ректору ФГБОУ ВО ИвГМА Минздрава России", align: :right
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right
      pdf.move_down 6
      pdf.move_down 6
      case campaign.campaign_type_id
      when 1
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), отказываюсь от зачисления по образовательной программе специалитета в рамках конкурса #{competitive_group.name}"
      when 4
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), отказываюсь от зачисления по образовательной программе ординатуры в рамках конкурса #{competitive_group.name} в соответствии с ранее поданным заявлением о согласии на зачислении."
      end
      pdf.move_down 6
      pdf.text "Подпись ___________________", align: :right
      
      pdf.render_file tempfile
    
      attachment = attachments.where(document_type: 'withdraw_application', document_id: competitive_group.id, template: true).first || Attachment.new
      attachment.entrant_application_id = id
      attachment.document_type = 'withdraw_application'
      attachment.document_id = competitive_group.id
      attachment.filename = "#{title}.pdf"
      attachment.mime_type = 'application/pdf'
      attachment.merged = false
      attachment.template = true
      md5 = ::Digest::MD5.file(tempfile).hexdigest
      attachment.data_hash = md5
      path = attachment.data_hash[0..2].split('').join('/')
      if attachment.save
        %x(mkdir -p #{Rails.root.join('storage', path)})
        file_path = Rails.root.join('storage', path, attachment.data_hash)
        %x(mv "#{tempfile}" "#{file_path}")
        %x(touch "#{file_path}")
      end
    end
    
    title = "Заявление об отзыве поданных в ИвГМА документов"
      tempfile = "#{[Rails.root, 'storage', 'tmp', title].join("/")}.pdf"
      pdf = Prawn::Document.new(page_size: "A5", page_layout: :landscape, :info => {
        :Title => title,
        :Author => "Vladimir Markovnin",
        :Subject => "Прием ИвГМА",
        :Creator => "ИвГМА",
        :Producer => "Prawn",
        :CreationDate => Time.now }
        )
      pdf.font_families.update("Ubuntu" => {
        :normal => "vendor/fonts/Ubuntu-R.ttf",
        :italic => "vendor/fonts/Ubuntu-RI.ttf",
        :bold => "vendor/fonts/Ubuntu-B.ttf"
        })
      pdf.font "Ubuntu"
      pdf.text title, style: :bold, :size => 14, align: :center
      pdf.move_down 6
      pdf.text "Ректору ФГБОУ ВО ИвГМА Минздрава России", align: :right
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right
      pdf.move_down 6
      pdf.move_down 6
      case campaign.campaign_type_id
      when 1
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), отказываюсь от участия в конкурсе / от зачисления на обучение по образовательным программам специалитета в ФГБОУ ВО ИвГМА Минздрава России и отзываю поданные документы. Прошу исключить меня из списков поступающих / зачисленных в  ФГБОУ ВО ИвГМА Минздрава России."
      when 4
        pdf.text "Я, #{fio} (№ личного дела #{application_number}), отказываюсь от участия в конкурсе / от зачисления на обучение по образовательным программам ординатуры в ФГБОУ ВО ИвГМА Минздрава России и отзываю поданные документы. Прошу исключить меня из списков поступающих / зачисленных в  ФГБОУ ВО ИвГМА Минздрава России."
      end
      pdf.move_down 6
      pdf.text "Подпись ___________________", align: :right
      
      pdf.render_file tempfile
    
      attachment = attachments.where(document_type: 'recall_application', document_id: id, template: true).first || Attachment.new
      attachment.entrant_application_id = id
      attachment.document_type = 'recall_application'
      attachment.document_id = id
      attachment.filename = "#{title}.pdf"
      attachment.mime_type = 'application/pdf'
      attachment.merged = false
      attachment.template = true
      md5 = ::Digest::MD5.file(tempfile).hexdigest
      attachment.data_hash = md5
      path = attachment.data_hash[0..2].split('').join('/')
      if attachment.save
        %x(mkdir -p #{Rails.root.join('storage', path)})
        file_path = Rails.root.join('storage', path, attachment.data_hash)
        %x(mv "#{tempfile}" "#{file_path}")
        %x(touch "#{file_path}")
      end
      
      title = "Титульный лист"
      tempfile = "#{[Rails.root, 'storage', 'tmp', title].join("/")}.pdf"
      pdf = Prawn::Document.new(page_size: "A4", :info => {
        :Title => title,
        :Author => "Vladimir Markovnin",
        :Subject => "Прием ИвГМА",
        :Creator => "ИвГМА",
        :Producer => "Prawn",
        :CreationDate => Time.now }
        )
      pdf.font_families.update("Ubuntu" => {
        :normal => "vendor/fonts/Ubuntu-R.ttf",
        :italic => "vendor/fonts/Ubuntu-RI.ttf",
        :bold => "vendor/fonts/Ubuntu-B.ttf"
        })
      pdf.font "Ubuntu"
      pdf.define_grid(:columns => 8, :rows => 7, :gutter => 5)
      pdf.grid([0, 0], [0,1]).bounding_box do
        pdf.text "#{application_number}", style: :bold, :size => 36
      end
      pdf.grid(0, 2).bounding_box do
        pdf.text "Сумма", :size => 16
      end
      pdf.grid(0, 3).bounding_box do
        pdf.text "ИД", :size => 16
        pdf.move_down 6
        pdf.text "#{'+' if achievements.count > 0}", :size => 16
      end
      case campaign.campaign_type_id
      when 1
        pdf.grid(0, 4).bounding_box do
          pdf.text "Х", :size => 16, align: :center
        end
        pdf.grid(0, 5).bounding_box do
          pdf.text "Б", :size => 16, align: :center
        end
        pdf.grid(0, 6).bounding_box do
          pdf.text "Р", :size => 16, align: :center
        end
      when 4
        pdf.grid(0, 4).bounding_box do
          pdf.text "Тест", :size => 16, align: :center
        end
      end
      pdf.grid([1, 0], [2, 7]).bounding_box do
        competitive_groups.where(education_source_id: 14).order(direction_id: :desc).each do |competitive_group|
          pdf.text "________  #{competitive_group.name}", :size => 14
          pdf.move_down 14
        end
        competitive_groups.where(education_source_id: 16).order(direction_id: :desc).each do |competitive_group|
          pdf.text "________  #{competitive_group.name} - #{target_contracts.where(competitive_group_id: competitive_group.id).map{|tc|tc.target_organization.target_organization_name}.compact.join(', ')}", :size => 14
          pdf.move_down 14
        end
        competitive_groups.where(education_source_id: 20).order(direction_id: :desc).each do |competitive_group|
          pdf.text "________  #{competitive_group.name}", :size => 14
          pdf.move_down 14
        end
        competitive_groups.where(education_source_id: 15).order(direction_id: :desc).each do |competitive_group|
          pdf.text "________  #{competitive_group.name}", :size => 14
          pdf.move_down 14
        end
      end
      pdf.grid([4, 0], [4, 7]).bounding_box do
        pdf.text "#{fio}", :size => 32, align: :center
      end
      pdf.grid([6, 0], [6, 7]).bounding_box do
        pdf.text "Адрес: #{address}", :size => 12
        pdf.move_down 4
        pdf.text "Телефон: #{phone}", :size => 12
        pdf.move_down 4
        pdf.text "Email: #{email}", :size => 12
      end
      
      pdf.render_file tempfile
    
      attachment = attachments.where(document_type: 'title_application', document_id: id, template: true).first || Attachment.new
      attachment.entrant_application_id = id
      attachment.document_type = 'title_application'
      attachment.document_id = id
      attachment.filename = "#{title}.pdf"
      attachment.mime_type = 'application/pdf'
      attachment.merged = false
      attachment.template = true
      md5 = ::Digest::MD5.file(tempfile).hexdigest
      attachment.data_hash = md5
      path = attachment.data_hash[0..2].split('').join('/')
      if attachment.save
        %x(mkdir -p #{Rails.root.join('storage', path)})
        file_path = Rails.root.join('storage', path, attachment.data_hash)
        %x(mv "#{tempfile}" "#{file_path}")
        %x(touch "#{file_path}")
      end
  end
end
