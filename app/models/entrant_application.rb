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
  belongs_to :target_organization
  has_many :achievements, dependent: :destroy
  has_many :olympic_documents, dependent: :destroy
  
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
      entrant_application = where(application_number: row["application_number"], campaign_id: campaign).first || new
      entrant_application.attributes = row.to_hash.slice(*accessible_attributes)
      entrant_application.campaign_id = campaign.id
      case true
      when campaign.education_levels.include?(5)
        entrant_application.budget_agr = nil if row.keys.include? 'lech_budget_agr'
        entrant_application.paid_agr = nil if row.keys.include? 'lech_paid_agr'
        entrant_application.budget_agr = competitive_groups.find_by_name('Лечебное дело. Бюджет.').id if row['lech_budget_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Лечебное дело. Бюджет. Крым.').id if row['lech_budget_krym_agr']
        entrant_application.paid_agr = competitive_groups.find_by_name('Лечебное дело. Внебюджет.').id if row['lech_paid_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Лечебное дело. Квота особого права.').id if row['lech_quota_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Лечебное дело. Квота особого права. Крым.').id if row['lech_quota_krym_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Лечебное дело. Целевые места.').id if row['lech_target_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Педиатрия. Бюджет.').id if row['ped_budget_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Педиатрия. Бюджет. Крым.').id if row['ped_budget_krym_agr']
        entrant_application.paid_agr = competitive_groups.find_by_name('Педиатрия. Внебюджет.').id if row['ped_paid_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Педиатрия. Квота особого права.').id if row['ped_quota_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Педиатрия. Квота особого права. Крым.').id if row['ped_quota_krym_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Педиатрия. Целевые места.').id if row['ped_target_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Стоматология. Бюджет.').id if row['stomat_budget_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Стоматология. Бюджет. Крым.').id if row['stomat_budget_krym_agr']
        entrant_application.paid_agr = competitive_groups.find_by_name('Стоматология. Внебюджет.').id if row['stomat_paid_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Стоматология. Квота особого права.').id if row['stomat_quota_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Стоматология. Квота особого права. Крым.').id if row['stomat_quota_krym_agr']
        entrant_application.budget_agr = competitive_groups.find_by_name('Стоматология. Целевые места.').id if row['stomat_target_agr']
        entrant_application.contracts = []
        entrant_application.contracts << 3 if row['contract lech']
        entrant_application.contracts << 9 if row['contract ped']
        entrant_application.contracts << 15 if row['contract stomat']
      when campaign.education_levels.include?(18)
        if row['agreement']
          if row['agreement'] =~ /Внебюджет/
            entrant_application.paid_agr = competitive_groups.find_by_name(row['agreement']).id
          else
            entrant_application.budget_agr = competitive_groups.find_by_name(row['agreement']).id
          end
        end
          entrant_application.target_organization_id = row['target1'].to_i if row['target1']
          entrant_application.target_organization_id = row['target2'].to_i if row['target2']
        entrant_application.contracts = []
      end
      if entrant_application.save!
          IdentityDocument.import_from_row(row, entrant_application) if row.keys.include? 'identity_document_type'
          EducationDocument.import_from_row(row, entrant_application) if row.keys.include? 'education_document_type'
        case true
        when campaign.education_levels.include?(5)
          BenefitDocument.import_from_row(row, entrant_application) if row.keys.include? 'benefit_document_type_id'
          OlympicDocument.import_from_row(row, entrant_application) if row.keys.include? 'olympic_id'
          Mark.import_from_row(row, entrant_application) if row.keys.include?('chemistry') || row.keys.include?('biology') || row.keys.include?('russian')
          Achievement.import_from_row(row, entrant_application)
          entrant_application.competitive_groups.each{|c| entrant_application.competitive_groups.delete(c)} if row.keys.include? 'Лечебное дело. Бюджет.'
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Бюджет.') if row['Лечебное дело. Бюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Бюджет. Крым.') if row['Лечебное дело. Бюджет. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Внебюджет.') if row['Лечебное дело. Внебюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Квота особого права.') if row['Лечебное дело. Квота особого права.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Квота особого права. Крым.') if row['Лечебное дело. Квота особого права. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Лечебное дело. Целевые места.') if row['Лечебное дело. Целевые места.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Бюджет.') if row['Педиатрия. Бюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Бюджет. Крым.') if row['Педиатрия. Бюджет. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Внебюджет.') if row['Педиатрия. Внебюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Квота особого права.') if row['Педиатрия. Квота особого права.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Квота особого права. Крым.') if row['Педиатрия. Квота особого права. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Педиатрия. Целевые места.') if row['Педиатрия. Целевые места.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Бюджет.') if row['Стоматология. Бюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Бюджет. Крым.') if row['Стоматология. Бюджет. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Внебюджет.') if row['Стоматология. Внебюджет.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Квота особого права.') if row['Стоматология. Квота особого права.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Квота особого права. Крым.') if row['Стоматология. Квота особого права. Крым.']
          entrant_application.competitive_groups << competitive_groups.find_by_name('Стоматология. Целевые места.') if row['Стоматология. Целевые места.']
        when campaign.education_levels.include?(18)
          Mark.import_from_row(row, entrant_application) if row.keys.include?('test_result')
          Achievement.import_from_row(row, entrant_application)
          entrant_application.competitive_groups.each{|c| entrant_application.competitive_groups.delete(c)} if row['spec1'] || row['spec2']
          if row['spec1']
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 14) if row['budg1'] == 1.to_s
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 15) if row['paid1'] == 1.to_s
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec1']}).where(education_source_id: 16) if row['target1']
          end
          if row['spec2']
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 14) if row['budg2'] == 1.to_s
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 15) if row['paid2'] == 1.to_s
            entrant_application.competitive_groups << competitive_groups.joins(:edu_programs).where(edu_programs: {name: row['spec2']}).where(education_source_id: 16) if row['target2']
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
        if identity_document.alt_entrant_last_name
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
    applications = campaign.entrant_applications.includes(:identity_documents).where.not(status_id: 6)
    errors[:dups_numbers] = find_dups_numbers(applications)
    errors[:lost_numbers] = find_lost_numbers(applications)
    errors[:dups_entrants] = find_dups_entrants(applications)
    target_competition_entrants_array = applications.joins(:competitive_groups).where(competitive_groups: {education_source_id: 16})
    errors[:empty_target_entrants] = find_empty_target_entrants(target_competition_entrants_array, applications.joins(:target_organization))
    errors[:not_original_target_entrants] = find_not_original_target_entrants(target_competition_entrants_array, applications.joins(:education_document).where.not(education_documents: {original_received_date: nil}))
    errors[:not_agreed_target_entrants] = find_not_agreed_entrants(applications)
    errors[:expired_passports] = find_expired_passports(applications)
    errors
  end
  
  def self.find_dups_numbers(applications)
    find_dups_numbers = []
    h = applications.select(:application_number).group(:application_number).count.select{|k, v| v > 1}
    h.each{|k, v| find_dups_numbers << applications.find_by_application_number(k)}
    find_dups_numbers
  end
  
  def self.find_lost_numbers(applications)
    application_numbers = applications.map(&:application_number)
    revoked_application_numbers = EntrantApplication.where(status_id: 6).map(&:application_number)
    max_number = application_numbers.max
    max_number ? (1..max_number).to_a - application_numbers - revoked_application_numbers : []
  end
  
  def self.find_dups_entrants(applications)
    IdentityDocument.includes(:entrant_application).where(entrant_applications: {id: applications}).where.not(entrant_applications: {status_id: 6}).group_by{|i| i.sn}.select{|k, v| v.size > 1}.map{|k, v| applications.joins(:identity_documents).where(identity_documents: {id: v})}.flatten
    
  end
  
  def self.find_empty_target_entrants(target_competition_entrants_array, target_organizations_array)
    (target_competition_entrants_array - target_organizations_array).sort
  end
                                                                                         
  def self.find_not_original_target_entrants(target_competition_entrants_array, original_received_array)
    (target_competition_entrants_array - original_received_array).sort
  end
  
  def self.find_not_agreed_entrants(applications)
   applications.joins(:competitive_groups).where(competitive_groups: {education_source_id: 16}).select{|a| a.competitive_groups.find_by_education_source_id(16).id != a.budget_agr}
  end

  def self.find_expired_passports(applications)
    applications.select{|a| Time.now.to_date > a.birth_date + 20.years}.select{|a| a.identity_documents.where.not(identity_document_date: nil).order(identity_document_date: :asc).last.identity_document_date < a.birth_date + 20.years}
  end
  
  def self.admission_volume_hash(campaign)
    admission_volume_hash = {}
    campaign.competitive_groups.includes(:competitive_group_item).sort_by{|cg| cg.edu_programs.map(&:name)}.group_by(&:direction_id).each do |k, v|
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
    entrant_applications = campaign.entrant_applications.select([:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :status_id, :benefit, :target_organization_id, :budget_agr, :paid_agr, :enrolled, :enrolled_date, :exeptioned, :snils, :birth_date, :registration_date, :gender_id]).order(:application_number).includes(:achievements, :education_document, :competitive_groups, :benefit_documents, :olympic_documents)
    
    entrance_test_items = campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    
    marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id)
    mark_values = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.value].inject(:merge)}}}.inject(:merge)
    
    mark_forms = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.form].inject(:merge)}}}.inject(:merge)
    
    entrant_applications_hash = {}
    entrant_applications.each do |entrant_application|
      entrant_applications_hash[entrant_application] = {}
      entrant_applications_hash[entrant_application][:competitive_groups] = entrant_application.competitive_groups.map(&:id)
      entrant_applications_hash[entrant_application][:mark_values] = []
      entrant_applications_hash[entrant_application][:mark_forms] = []
      entrance_test_items.each do |entrance_test_item|
        mark_value = mark_values[entrant_application.id].inject(:merge)[entrance_test_item.subject_id]
        mark_form = mark_forms[entrant_application.id].inject(:merge)[entrance_test_item.subject_id]
        entrant_applications_hash[entrant_application][:mark_values] << mark_value if mark_value >= entrance_test_item.min_score
        entrant_applications_hash[entrant_application][:mark_forms] << mark_form
      end
      entrant_applications_hash[entrant_application][:summa] = entrant_applications_hash[entrant_application][:mark_values].size == entrance_test_items.size ? entrant_applications_hash[entrant_application][:mark_values].sum : 0
      entrant_applications_hash[entrant_application][:achievements] = entrant_application.achievements.order(:institution_achievement_id).map(&:value)
      achievements_sum = entrant_applications_hash[entrant_application][:achievements].sum
      achievements_limit = 10 if campaign.education_levels.include?(5)
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
          test_result_type = application.marks.map(&:form).include?('аккредитация') ? 'аккредитация' : 'ординатура'
          test_result_year = case true
                              when test_result_type == 'ординатура'
                                2018
                              when test_result_type == 'аккредитация' && application.education_document.education_document_date.year == 2018
                                2018
                              else
                                2017
                              end
          row = [
            application.snils,
            application.entrant_last_name,
            application.entrant_first_name,
            application.entrant_middle_name,
            oid,
            1,
            application.birth_date.strftime("%d.%m.%Y"),
            citizenship,
            competitive_group.edu_programs.last.code,
            (competitive_group.education_source_id == 15 ? 'договор' : 'бюджет'),
            application.registration_date.strftime("%d.%m.%Y"),
            (competitive_group.education_source_id == 16 ? 'да' : 'нет'),
            test_result_type,
            application.marks.map(&:organization_uid).first,
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
            1,
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
        test_result_type = application.marks.map(&:form).include?('аккредитация') ? 'аккредитация' : 'ординатура'
        test_result_year = case true
                            when test_result_type == 'ординатура'
                              2018
                            when test_result_type == 'аккредитация' && application.education_document.education_document_date.year == 2018
                              2018
                            else
                              2017
                            end
        row = [
          application.snils,
          oid,
          application.birth_date.strftime("%d.%m.%Y"),
          test_result_type,
          test_result_year,
          application.marks.map(&:organization_uid).first,
          application.education_document.education_speciality_code
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
      applications.each do |application, values|
        application.competitive_groups.each do |competitive_group|
          status = case application.status_id
                    when 6
                      3
                    when 4
                      application.enrolled && application.enrolled == competitive_group.id ? 1 : 2
                    end
          order_number = case application.enrolled_date
                          when Date.new(2018, 8, 13)
                            '111-ипо'
                          when Date.new(2018, 8, 15)
                            '112-ипо'
                          when Date.new(2018, 8, 17)
                            '114-ипо'
                          end
          zero_array = ('а'..'г').zip([0, 0, 0, 0]).map{|i| i.join('-')}
          values[:achievements] = values[:achievements].map{|a| a.round()}
          achievements_array = ('а'..'г').zip(values[:achievements].map{|a| a.round()}).map{|i| i.join('-')}
          test_result = values[:mark_values].sum.round() == 0 ? application.marks.sum(:value).round() : values[:mark_values].sum.round()
          full_summa = values[:full_summa].round() == 0 ? [test_result, values[:achievements].sum].sum : values[:full_summa].round()
          if (values[:achievements][2] - 10) % 5 == 0
            achievements_array[2] = achievements_array[2].sub('в-', 'в1-')
            zero_array[2] = zero_array[2].sub('в-', 'в1-')
          else
            achievements_array[2] = achievements_array[2].sub('в-', 'в2-')
            zero_array[2] = zero_array[2].sub('в-', 'в2-')
          end
          achievements = (achievements_array - zero_array).compact.size == 0 ? nil : (achievements_array - zero_array).compact.join(',')
          row = [
            application.snils,
            oid,
            1,
            application.birth_date.strftime("%d.%m.%Y"),
            competitive_group.edu_programs.last.code,
            (competitive_group.education_source_id == 15 ? 'договор' : 'бюджет'),
            (competitive_group.education_source_id == 16 ? 'да' : 'нет'),
            application.registration_date.strftime("%d.%m.%Y"),
            full_summa,
            (test_result if test_result > 0),
            achievements,
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
  
end
