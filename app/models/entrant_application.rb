class EntrantApplication < ActiveRecord::Base
  require 'builder'
  require 'net/http'
  
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
  has_many :tickets, dependent: :destroy
  has_one :contragent, dependent: :destroy
  
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
  
  def self.import_to_epgu(file, campaign)
    %x(mkdir -p "#{Rails.root.join('storage', 'epgu')}")
    entrance_test_items = campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    entrance_test_items_size = entrance_test_items.size
    admission_volume_hash = admission_volume_hash(campaign)
    entrant_applications_hash = entrant_applications_hash(campaign)
    epgu_entrants = {}
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).to_a.each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      epgu_entrants[row['competitive_group_name']] ||= []
      epgu_entrants[row['competitive_group_name']].push Hash[row['snils'] => row['uidepgu']]
    end
    admission_volume_hash.each do |direction_id, competitive_groups|
      competitive_groups.sort_by{|competitive_group, numbers| competitive_group.name}.select{|competitive_group, numbers| competitive_group.order_end_date > Time.now.to_date}.each do |competitive_group, numbers|
        if epgu_entrants[competitive_group.name]
          xml = ::Builder::XmlMarkup.new
          xml.PackageData do |package_data|
            package_data.CompetitiveGroupApplicationsList do |competitive_group_applications_list|
              competitive_group_applications_list.UIDCompetitiveGroup competitive_group.id
              competitive_group_applications_list.AdmissionVolume numbers
              competitive_group_applications_list.CountFirstStep numbers
              competitive_group_applications_list.CountSecondStep 0
              competitive_group_applications_list.Changed Time.now.to_datetime.to_s.gsub('+00', '+03')
              competitive_group_applications_list.Applications do |applications|
                n = 0
                entrant_applications = entrant_applications_hash.select{|k, v| v[:competitive_groups].include?(competitive_group.id) && v[:summa] > 0 && k.status_id == 4 && v[:mark_values].select{|m| m > 41}.count == entrance_test_items_size}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit], v[:achievements_sum_abs]]}.reverse
                examless_applications = entrant_applications.select{|k, v| v[:examless] && competitive_group.education_source_id != 15}
                examless_applications.each do |k, v|
                  n += 1
                  applications.Application do |application|
                    application.IDApplicationChoice do |id_application_choice|
                      if epgu_entrants[competitive_group.name].select{|item| item[k.snils]}.empty?
                        id_application_choice.UID k.snils
                      else
                        id_application_choice.UIDEpgu epgu_entrants[competitive_group.name].select{|item| item[k.snils]}.first.values.first
                      end
                    end
                    application.Rating n
                    application.WithoutTests true
                    application.ReasonWithoutTests 'Олимпиада школьников'
                    application.Mark v[:achievements_sum].to_i
                    application.Benefit k.benefit
                    application.ReasonBenefit ('Документ, подтверждающий наличие особого права' if k.benefit)
                    application.Agreed k.budget_agr == competitive_group.id ? true : false
                    application.Original false
                    application.Enlisted k.enrolled ? 1 : 5
                  end
                end
                (entrant_applications - examless_applications).each do |k, v|
                  n += 1
                  applications.Application do |application|
                    application.IDApplicationChoice do |id_application_choice|
                      if epgu_entrants[competitive_group.name].select{|item| item[k.snils]}.empty?
                        id_application_choice.UID k.snils
                      else
                        id_application_choice.UIDEpgu epgu_entrants[competitive_group.name].select{|item| item[k.snils]}.first.values.first
                      end
                    end
                    application.Rating n
                    application.WithoutTests false
                    application.ReasonWithoutTests 
                    application.EntranceTest1 'Химия'
                    application.Result1 v[:mark_values][0]
                    application.EntranceTest2 'Биология'
                    application.Result2 v[:mark_values][1]
                    application.EntranceTest3 'Русский язык'
                    application.Result3 v[:mark_values][2]
                    application.Mark v[:achievements_sum].to_i
                    application.Benefit k.benefit
                    application.ReasonBenefit ('Документ, подтверждающий наличие особого права' if k.benefit)
                    application.SumMark v[:full_summa].to_i
                    application.Agreed k.budget_agr == competitive_group.id ? true : false
                    application.Original false
                    application.Enlisted k.enrolled ? 1 : 5
                  end
                end
              end
            end
          end
          tempfile = "#{[Rails.root, 'storage', 'epgu', competitive_group.id].join("/")}.xml"
          File.open(tempfile, 'w').write(xml.target!)
        end
      end
    end
    FileUtils.cp(Rails.root.join('storage', 'epgu.zip'), Rails.root.join('storage', 'epgu.zip.bak'))
    FileUtils.rm(Rails.root.join('storage', 'epgu.zip'))
    FileUtils.cd([Rails.root, 'storage'].join("/"))
    %x(zip -r epgu "./epgu")
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
    errors[:consent_without_contract_entrants] = find_consent_without_contract_entrants(applications, campaign)
    errors[:not_target_target_contract_entrants] = find_not_target_target_contract_entrants(applications)
    errors[:not_target_contract_target_entrants] = find_not_target_contract_target_entrants(applications)
    errors[:expired_passports] = find_expired_passports(applications.where.not(birth_date: nil))
    errors[:empty_achievements] = find_empty_achievements(applications)
    errors[:elders] = find_elders(applications)
    errors[:empty_marks] = find_empty_marks(applications)
    errors[:new_contracts] = find_new_contracts(applications)
    errors[:consent_without_agr] = find_consent_without_agr(applications)
    errors
  end
  
  def self.find_empty_marks(applications)
    applications.joins(:marks).where(status_id: 4, marks: {value: 0, form: 'ЕГЭ'})
  end
  
  def self.find_new_contracts(applications)
    applications.joins(:attachments).includes(:contracts).where(attachments: {document_type: 'contract', template: false}).select{|a| a.contracts.map(&:competitive_group_id).uniq.sort != a.attachments.where(document_type: 'contract', template: false).map(&:document_id).uniq.sort}.uniq
  end
  
  def self.find_consent_without_agr(applications)
    applications.joins(:attachments).where(attachments: {document_type: ['consent_application', 'withdraw_application'], template: false}, budget_agr: nil).select{|a| a.attachments.where(document_type: 'consent_application', template: false).map(&:document_id).uniq.sort != a.attachments.where(document_type: 'withdraw_application', template: false).map(&:document_id).uniq.sort}.uniq
  end
  
  def self.find_elders(applications)
    applications.select{|a| Time.now.to_date > a.birth_date + 20.years}.select{|a| a.identity_documents.count == 1}
  end
  
  def self.find_empty_achievements(applications)
    applications.joins(:achievements).where(status_id: 4, achievements: {value: 0})
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
                                                                                         
  def self.find_consent_without_contract_entrants(applications, campaign)
    competitive_groups = campaign.competitive_groups.where(education_source_id: 15)
    applications.joins(:competitive_groups).where(competitive_groups: {id: competitive_groups}, budget_agr: [competitive_groups.map(&:id)]).select{|a| a.contracts.where(competitive_group_id: a.budget_agr).empty?}.uniq.sort_by(&:application_number)
  end
  
  def self.find_not_target_target_contract_entrants(applications)
   applications.joins(:target_contracts).includes(:competitive_groups).select{|a| a.competitive_groups.where(education_source_id: 16).empty?}.sort_by(&:application_number)
  end
  
  def self.find_not_target_contract_target_entrants(applications)
   applications.joins(:competitive_groups).includes(:target_contracts).where(competitive_groups: {education_source_id: 16}).select{|a| a.target_contracts.empty?}.sort_by(&:application_number)
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
    entrant_applications = campaign.entrant_applications.select([:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :status_id, :benefit, :budget_agr, :paid_agr, :enrolled, :enrolled_date, :exeptioned, :snils, :birth_date, :registration_date, :gender_id, :nationality_type_id, :contracts, :return_documents_date, :registration_number]).order(:application_number).includes(:achievements, :education_document, :competitive_groups, :benefit_documents, :olympic_documents, :target_contracts).where(status_id: 4)
    
    entrance_test_items = campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    
    marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id)
    mark_values = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.value].inject(:merge)}}}.inject(:merge)
    
    mark_forms = marks.map{|a, ms| {a => ms.map{|m| [m.subject_id => m.form].inject(:merge)}}}.inject(:merge)
    
    achievements = Achievement.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id)
    achievement_values = achievements.map{|a, achs| {a => achs.sort_by(&:institution_achievement_id).map(&:value)}}.inject(:merge) || []
    
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
      entrant_applications_hash[entrant_application][:achievements_sum_abs] = achievements_sum
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
            4,
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
            4,
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
          '06.08.2021',
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
            if achievement.value > 0
              case achievement.institution_achievement_id
              when 38
                achievements_array << 'а'
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
                achievements_array << "з-#{achievement.value.round()}"
              end
            end
          end
          achievements = achievements_array.join(',')
          test_result = values[:mark_values].sum.round() == 0 ? application.marks.sum(:value).round() : values[:mark_values].sum.round()
          achievements_sum = values[:achievements] ? values[:achievements].sum : 0
          full_summa = values[:full_summa].round() == 0 ? [test_result, achievements_sum].sum.round() : values[:full_summa].round()
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
  
  def generate_entrant_application
    %x(mkdir -p "#{Rails.root.join('storage', 'qr')}")
    path = Rails.root.join('storage', 'qr', data_hash)
    %x(qrencode -o "#{path}" "https://isma.ivanovo.ru/entrants/#{data_hash}")
    countries = Dictionary.find_by_name('Страна').items
    identity_documents_list = Dictionary.find_by_name('Тип документа, удостоверяющего личность').items
    benefit_types = Dictionary.find_by_name('Вид льготы').items
    document_types = Dictionary.find_by_name('Тип документа').items
    if application_number
      title = "Заявление о приеме в ИвГМА № #{application_number}"
    else
      title = "Заявление о приеме в ИвГМА зарегистрировано под № #{registration_number}"
    end
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
    pdf.text "И. о. ректора ФГБОУ ВО ИвГМА Минздрава России", size: 10, align: :right
    pdf.move_down 4
    pdf.text "д.м.н., проф. Е. В. Борзову", size: 10, align: :right
    pdf.move_down 6
    case campaign.campaign_type_id
    when 1
      pdf.text "Я, #{fio}, прошу допустить меня к участию в конкурсе в ФГБОУ ВО ИвГМА Минздрава России на программы специалитета", size: 10
    when 4
      pdf.text "Я, #{fio}, прошу допустить меня к участию в конкурсе в ФГБОУ ВО ИвГМА Минздрава России на программы ординатуры", size: 10
    end
    pdf.move_down 6
    pdf.text "Персональные данные", size: 12
    pdf.move_down 4
    pdf.text "Дата рождения: #{birth_date.strftime("%d.%m.%Y")}", size: 10 if birth_date
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
    pdf.text "#{identity_documents_list.select{|item| item['id'] == identity_document.identity_document_type}[0]['name']}: #{identity_document.identity_document_data}", size: 10 if identity_document
    pdf.move_down 6
    pdf.text "Документ об образовании", size: 12
    pdf.move_down 4
    pdf.text "#{education_document.education_document_data}", size: 10 if education_document
    pdf.move_down 4
    pdf.move_down 4
    if campaign.campaign_type_id == 4
      other_documents.where(name: 'Свидетельство об аккредитации специалиста').each do |other_document|
        pdf.text "#{other_document.other_document_data}", size: 12
        pdf.move_down 6
      end
      other_documents.where(name: 'Выписка из итогового протокола заседания аккредитационной комиссии').each do |other_document|
        pdf.text "#{other_document.other_document_data}", size: 12
        pdf.move_down 6
      end
    end
    unless snils.empty?
      pdf.text "Номер СНИЛС #{snils}", size: 12
    else
      pdf.text "Подтверждаю отсутствие СНИЛС", size: 12
      pdf.move_down 4
      pdf.text "Подпись ___________________", size: 10, align: :right
    end
    pdf.move_down 6
    pdf.text "Прошу рассмотреть мои документы для участия в следующих конкурсах:", size: 12
    pdf.move_down 4
    competitive_groups.each do |competitive_group|
      pdf.text "- #{competitive_group.name}", size: 10
      pdf.move_down 6
    end
    if olympionic || benefit
      pdf.text "Имею особые права:", size: 12
      pdf.move_down 4
      olympic_documents.each do |olympic_document|
        #pdf.text "Имею право на #{benefit_types.select{|item| item['id'] == olympic_document.benefit_type_id}[0]['name']}", size: 10
        #pdf.move_down 4
        #pdf.text "Реквизиты документа, дающего особое право: #{document_types.select{|item| item['id'] == olympic_document.olympic_document_type_id}[0]['name']} #{olympic_document.olympic_document_data}", size: 10
        pdf.text "Реквизиты документа, дающего особое право: #{olympic_document.olympic_document_data}", size: 10
        pdf.move_down 4
      end
      benefit_documents.each do |benefit_document|
        #pdf.text "Имею право на #{'прием' if benefit_document.benefit_type_id == 4} #{benefit_types.select{|item| item['id'] == benefit_document.benefit_type_id}[0]['name']}", size: 10
        #pdf.move_down 4
        #pdf.text "Реквизиты документа, дающего особое право: #{document_types.select{|item| item['id'] == benefit_document.benefit_document_type_id}[0]['name']} #{benefit_document.benefit_document_data}", size: 10
        pdf.text "Реквизиты документа, дающего особое право: #{benefit_document.benefit_document_data}", size: 10
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
      pdf.move_down 6
    end
    unless achievements.empty?
      pdf.text "Имею следующие индивидуальные достижения", size: 12
      pdf.move_down 4
      achievements.each do |achievement|
        pdf.text "- #{achievement.institution_achievement.name}", size: 10
        pdf.move_down 6
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
    if marks.map(&:form).include?('ВИ')
      pdf.text "Ознакомлен с регламентом проведения вступительных испытаний, проводимых академией самостоятельно", size: 10
      pdf.move_down 4
      pdf.text "Подпись ___________________", size: 10, align: :right
      pdf.move_down 4
    end
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
      pdf.text "И. о. ректора ФГБОУ ВО ИвГМА Минздрава России", align: :right, size: 10
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right, size: 10
      pdf.move_down 6
      pdf.text "Я, #{fio}, прошу учесть в качестве вступительного испытания результаты тестирования в рамках процедуры аккредитации, пройденной в ______ году на базе __________________________________________, по специальности ________________________", size: 10
      pdf.move_down 6  
      pdf.text "Подпись ___________________", size: 10, align: :right
    end
    
    pdf.move_down 4
    pdf.text "Ссылка на личный кабинет"
    %x(ls "#{Rails.root.join('storage', 'qr')}")
    pdf.image "#{path}"

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
    %x(rm "#{path}")
    path = attachment.data_hash[0..2].split('').join('/')
    if attachment.save
      %x(mkdir -p #{Rails.root.join('storage', path)})
      file_path = Rails.root.join('storage', path, attachment.data_hash)
      %x(mv "#{tempfile}" "#{file_path}")
      %x(touch "#{file_path}")
    end
  end
  
  def generate_consent_applications
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
      pdf.text "И. о. ректора ФГБОУ ВО ИвГМА Минздрава России", align: :right
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right
      pdf.move_down 6
      pdf.move_down 6
      case campaign.campaign_type_id
      when 1
        pdf.text "Я, #{fio}, прошу зачислить меня на обучение по образовательной программе специалитета в рамках конкурса #{competitive_group.name}"
      when 4
        pdf.text "Я, #{fio}, прошу зачислить меня на обучение по образовательной программе ординатуры в рамках конкурса #{competitive_group.name}"
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
        pdf.text "ОБРАТИТЕ ВНИМАНИЕ!!! Единовременно можно подать только ОДНО заявление о согласии на зачисление (только по ОДНОМУ конкурсу). Если Вы подадите одновременно несколько заявлений о согласии, это будет являться нарушением правил приема, и Вы не будете зачислены в нашу академию. При необходимости Вы сможете отозвать заявление о согласии (написав и прикрепив заявление об отзыве согласия) и подать согласие на другой конкурс. На бюджетные конкурсы можно последовательно подать лишь ЧЕТЫРЕ согласия, на внебюджетные - неограниченное количество раз."
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
    end
  end
  
  def generate_withdraw_applications
    competitive_groups.each do |competitive_group|
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
      pdf.text "И. о. ректора ФГБОУ ВО ИвГМА Минздрава России", align: :right
      pdf.move_down 6
      pdf.text "д.м.н., проф. Е. В. Борзову", align: :right
      pdf.move_down 6
      pdf.move_down 6
      case campaign.campaign_type_id
      when 1
        pdf.text "Я, #{fio}, отказываюсь от зачисления по образовательной программе специалитета в рамках конкурса #{competitive_group.name}"
      when 4
        pdf.text "Я, #{fio}, отказываюсь от зачисления по образовательной программе ординатуры в рамках конкурса #{competitive_group.name} в соответствии с ранее поданным заявлением о согласии на зачислении."
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
  end
  
  def generate_recall_application
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
    pdf.text "И. о. ректора ФГБОУ ВО ИвГМА Минздрава России", align: :right
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
  end
  
  def generate_title_application
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
    pdf.grid([0, 0], [0, 1]).bounding_box do
      pdf.text "#{application_number}", style: :bold, :size => 36
    end
    pdf.grid([0, 1], [0, 5]).bounding_box do
      pdf.text "Дата регистрации #{registration_date}", style: :bold, :size => 14, align: :center
    end
    pdf.grid(0, 6).bounding_box do
      pdf.text "Сумма", :size => 16, align: :right
    end
    pdf.grid(0, 6).bounding_box do
      pdf.text "ИД", :size => 16, valign: :center, align: :right
    end
    pdf.grid(0, 7).bounding_box do
      pdf.text "#{'+' if achievements.count > 0}", :size => 16, valign: :center, align: :right
    end
    case campaign.campaign_type_id
    when 1
      pdf.grid(1, 6).bounding_box do
        pdf.text "Х", :size => 16, align: :right
      end
      pdf.grid(1, 6).bounding_box do
        pdf.text "Б", :size => 16, valign: :center, align: :right
      end
      pdf.grid(1, 6).bounding_box do
        pdf.text "Р", :size => 16, valign: :bottom, align: :right
      end
    when 4
      pdf.grid(1, 6).bounding_box do
        pdf.text "Тест", :size => 16, align: :right
      end
    end
    pdf.grid([1, 0], [3, 6]).bounding_box do
      competitive_groups.where(education_source_id: 14).order(direction_id: :desc).each do |competitive_group|
        pdf.text "________  #{competitive_group.name}", :size => 14
        pdf.move_down 14
      end
      competitive_groups.where(education_source_id: 16).order(direction_id: :desc).each do |competitive_group|
        pdf.text "________  #{competitive_group.name}", :size => 14
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
    pdf.grid([7, 0], [7, 7]).bounding_box do
      pdf.text "Язык: #{language}", :size => 14
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
  
  def generate_contracts(competitive_group_id)
    competitive_group = CompetitiveGroup.find(competitive_group_id)
#     получение справочника дисциплин
    method = '/dictionarydetails'
    request = Request.data('/dictionarydetails', {dictionary_number: 10})
    http_params = Request.http_params()
    http = Net::HTTP.new(http_params[:uri_host], http_params[:uri_port], http_params[:proxy_ip], http_params[:proxy_port])
    headers = {'Content-Type' => 'text/xml'}
    response = http.post(http_params[:uri_path] + method, request, headers)
    xml = Nokogiri::XML(response.body)
    direction_name = xml.at("DirectionID:contains('#{competitive_group.direction_id}')").parent.at_css("Name").text
    direction_code = xml.at("DirectionID:contains('#{competitive_group.direction_id}')").parent.at_css("NewCode").text
    if campaign.campaign_type_id == 1
      case direction_name
      when 'Лечебное дело'
        education_duration = '6 лет'
        total_fee = '907 500 (девятьсот семь тысяч пятьсот)'
        first_year_fee = '151 250 (сто пятьдесят одна тысяча двести пятьдесят)'
      when 'Педиатрия'
        education_duration = '6 лет'
        total_fee = '907 500 (девятьсот семь тысяч пятьсот)'
        first_year_fee = '151 250 (сто пятьдесят одна тысяча двести пятьдесят)'
      when 'Стоматология'
        education_duration = '5 лет'
        total_fee = '907 500 (девятьсот семь тысяч пятьсот)'
        first_year_fee = '181 500 (сто восемьдесят одна тысяча пятьсот)'
      end
    end
    if campaign.campaign_type_id == 4
      if nationality_type_id == 1
        case direction_name
        when /Стоматология/
          education_duration = '2 года'
          total_fee = '387 200 (триста восемьдесят семь тысяч двести)'
          first_year_fee = '193 600 (сто девяносто три тысячи шестьсот)'
        else
          education_duration = '2 года'
          total_fee = '338 800 (триста тридцать восемь тысяч восемьсот)'
          first_year_fee = '169 400 (сто шестьдесят девять тысяч четыреста)'
        end
      else
        case direction_name
        when /Стоматология/
          education_duration = '2 года'
          total_fee = '411 400 (четыреста одиннадцать тысяч четыреста)'
          first_year_fee = '205 700 (двести пять тысяч семьсот)'
        else
          education_duration = '2 года'
          total_fee = '363000 (триста шестьдесят три тысячи)'
          first_year_fee = '181 500 (сто восемьдесят одна тысяча пятьсот)'
        end
      end
    end
    current_identity_document = identity_documents.order(:identity_document_date).last
    selfcontragent = [current_identity_document.identity_document_series.strip, current_identity_document.identity_document_number.strip].compact.join('') == [contragent.identity_document_serie.strip, contragent.identity_document_number.strip].compact.join('')
    title = "Договор об образовании на обучение по программам высшего образования"
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
    pdf.text 'ДОГОВОР №', style: :bold, size: 11, align: :center
    pdf.text 'ОБ ОБРАЗОВАНИИ НА ОБУЧЕНИЕ  ПО ПРОГРАММАМ ВЫСШЕГО ОБРАЗОВАНИЯ', style: :bold, size: 11, align: :center
    pdf.move_down 6
    if campaign.campaign_type_id == 1
      pdf.text 'г. Иваново                                                                                                                                        «23» августа 2021 года', size: 11
    end
    if campaign.campaign_type_id == 4
      pdf.text 'г. Иваново                                                                                                                                        «16» августа 2021 года', size: 11
    end
    s = selfcontragent ? "#{contragent.fio}, #{gender_id == 1 ? 'именуемый' : 'именуемая'} в дальнейшем «Заказчик» и «Обучающийся»" : "#{contragent.fio}, именуемый(ая) в дальнейшем «Заказчик», и #{fio}, #{gender_id == 1 ? 'именуемый' : 'именуемая'} в дальнейшем «Обучающийся»"
    if campaign.campaign_type_id == 1
      pdf.text "Федеральное государственное бюджетное образовательное учреждение высшего образования «Ивановская государственная медицинская академия» Министерства здравоохранения Российской Федерации, осуществляющее образовательную деятельность на основании лицензии № 2258 от «08» июля 2016 г., выданной Федеральной службой по надзору в сфере образования и науки (бессрочно), и свидетельства о государственной аккредитации № 2300 от «20» октября 2016 г., выданного Федеральной службой по надзору в сфере образования и науки (на срок до 11.12.2022 г.), именуемое в дальнейшем «Исполнитель», в лице и. о. ректора Борзова Евгения Валерьевича, действующего на основании устава и приказов №33пк от 15.03.2021 и №122пк от 22.06.2021, и #{s}, совместно именуемые «Стороны», заключили настоящий Договор (далее - Договор) о нижеследующем:", size: 11, align: :justify
    end
    if campaign.campaign_type_id == 4
      pdf.text "Федеральное государственное бюджетное образовательное учреждение высшего образования «Ивановская государственная медицинская академия» Министерства здравоохранения Российской Федерации, осуществляющее образовательную деятельность на основании лицензии № 2258 от «08» июля 2016 г., выданной Федеральной службой по надзору в сфере образования и науки (бессрочно), и свидетельства о государственной аккредитации № 2300 от «20» октября 2016 г., выданного Федеральной службой по надзору в сфере образования и науки (на срок до 11.12.2022 г.), именуемое в дальнейшем «Исполнитель», в лице и. о. проректора по последипломному образованию и клинической работе Полозова Владимира Витальевича, действующего на основании  доверенности № 19 от 01.07.2021, и #{s}, совместно именуемые «Стороны», заключили настоящий Договор (далее - Договор) о нижеследующем:", size: 11, align: :justify
    end
      
    pdf.move_down 6
    pdf.text 'I. ПРЕДМЕТ ДОГОВОРА', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text "1.1.Исполнитель обязуется предоставить образовательную услугу, а #{selfcontragent ? 'Обучающийся' : 'Заказчик'} обязуется оплатить обучение по образовательной программе:", size: 11, align: :justify
    if campaign.campaign_type_id == 1
      pdf.text 'вид: основная профессиональная образовательная - образовательная программа высшего образования - программа специалитета; уровень: высшее образование – специалитет;', size: 11, align: :justify
    end
    if campaign.campaign_type_id == 4
      pdf.text 'вид: образовательная программа высшего образования - программа подготовки научно-педагогических кадров в ординатуре; уровень: высшее образование;', size: 11, align: :justify
    end
    pdf.text "направление подготовки, специальность/направленность: #{direction_code} #{direction_name} по очной форме обучения в пределах федерального государственного образовательного стандарта в соответствии с учебными планами и образовательными программами Исполнителя.", size: 11, align: :justify
    pdf.text "1.2. Срок освоения образовательной программы (продолжительность обучения) на момент подписания договора составляет #{education_duration}.", size: 11, align: :justify
    if campaign.campaign_type_id == 1
      pdf.text '1.3. После освоения Обучающимся образовательной программы и успешного прохождения государственной итоговой аттестации ему выдается диплом специалиста', size: 11, align: :justify
    end
    if campaign.campaign_type_id == 4
      pdf.text '1.3. После освоения Обучающимся образовательной программы и успешного прохождения государственной итоговой аттестации ему выдается диплом об окончании ординатуры', size: 11, align: :justify
    end
    pdf.text 'Обучающемуся, не прошедшему итоговой аттестации или получившему на итоговой аттестации неудовлетворительные результаты, а также Обучающемуся, освоившему часть образовательной программы и (или) отчисленному, выдается справка об обучении или о периоде обучения по образцу, самостоятельно устанавливаемому Исполнителем.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'II. ВЗАИМОДЕЙСТВИЕ СТОРОН', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text '2.1. Исполнитель вправе:', size: 11, align: :justify
    pdf.text '2.1.1. Самостоятельно осуществлять образовательный процесс, устанавливать системы оценок, формы, порядок и периодичность промежуточной аттестации Обучающегося;', size: 11, align: :justify
    pdf.text '2.1.2. Применять к Обучающемуся меры поощрения и меры дисциплинарного взыскания в соответствии с законодательством Российской Федерации, учредительными документами Исполнителя, настоящим Договором и локальными нормативными актами Исполнителя.', size: 11, align: :justify
    pdf.text '2.2. Возможно предоставление Обучающемуся места в студенческом общежитии при наличии свободных мест в соответствии с отдельно заключенным договором. Стоимость проживания в общежитии определяется прейскурантом и не входит в сумму, подлежащую уплате по настоящему Договору.', size: 11, align: :justify
    pdf.text '2.3. Исполнитель не принимает на себя обязательств по выплате Обучающемуся стипендии, возмещению материальных расходов обучающегося, связанных с передвижениями по территории РФ, по страхованию его жизни, здоровья и имущества.', size: 11, align: :justify
    pdf.text '2.4. Заказчик вправе получать информацию от Исполнителя по вопросам организации и обеспечения надлежащего предоставления услуг, предусмотренных разделом I настоящего Договора.', size: 11, align: :justify
    pdf.text '2.5. Обучающемуся предоставляются академические права в соответствии с частью 1 статьи 34 Федерального закона от 29 декабря 2012 г. N 273-ФЗ "Об образовании в Российской Федерации". Обучающийся также вправе:', size: 11, align: :justify
    pdf.text '2.5.1. Получать информацию от Исполнителя по вопросам организации и обеспечения надлежащего предоставления услуг, предусмотренных разделом I настоящего Договора;', size: 11, align: :justify
    pdf.text '2.5.2. Пользоваться в порядке, установленном локальными нормативными актами, имуществом Исполнителя, необходимым для освоения образовательной программы;', size: 11, align: :justify
    pdf.text '2.5.3. Принимать в порядке, установленном локальными нормативными актами, участие в социально-культурных, оздоровительных и иных мероприятиях, организованных Исполнителем;', size: 11, align: :justify
    pdf.text '2.5.4. Получать полную и достоверную информацию об оценке своих знаний, умений, навыков и компетенций, а также о критериях этой оценки.', size: 11, align: :justify
    pdf.text '2.6. Исполнитель обязан:', size: 11, align: :justify
    pdf.text '2.6.1. Зачислить Обучающегося, выполнившего установленные законодательством Российской Федерации, учредительными документами, локальными нормативными актами Исполнителя условия приема, в качестве Студента', size: 11
    pdf.text '2.6.2. Довести до Заказчика информацию, содержащую сведения о предоставлении платных образовательных услуг в порядке и объеме, которые предусмотрены Законом Российской Федерации от 7 февраля 1992 г. N 2300-1 "О защите прав потребителей" и Федеральным законом от 29 декабря 2012 г. N 273-ФЗ "Об образовании в Российской Федерации";', size: 11, align: :justify
    pdf.text '2.6.3. Организовать и обеспечить надлежащее предоставление образовательных услуг, предусмотренных разделом I настоящего Договора. Образовательные услуги оказываются в соответствии с федеральным государственным образовательным стандартом, учебным планом, в том числе индивидуальным, и расписанием занятий Исполнителя;', size: 11, align: :justify
    pdf.text '2.6.4. Обеспечить Обучающемуся предусмотренные выбранной образовательной программой условия ее освоения;', size: 11, align: :justify
    pdf.text '2.6.5. Принимать от Обучающегося и (или) Заказчика плату за образовательные услуги;', size: 11
    pdf.text '2.6.6. Обеспечить Обучающемуся уважение человеческого достоинства, защиту от всех форм физического и психического насилия, оскорбления личности, охрану жизни и здоровья.', size: 11, align: :justify
    pdf.text '2.7. Заказчик и (или) Обучающийся обязан(-ы) своевременно вносить плату за предоставляемые Обучающемуся образовательные услуги, указанные в разделе I настоящего Договора, в размере и порядке, определенными настоящим Договором, а также предоставлять платежные документы, подтверждающие такую оплату.', size: 11, align: :justify
    pdf.text '2.7.1.Заказчик и (или) Обучающийся обязан(-ы) предоставить Исполнителю оригиналы Договора в течение 1 (одного) месяца с начала учебного года (в случае заключения настоящего Договора путем обмена их сканированными подписанными копиями).', size: 11
    pdf.text '2.8. Обучающийся также обязан:', size: 11, align: :justify
    pdf.text '2.8.1. Своевременно сообщать Исполнителю о причинах, препятствующих добросовестному исполнению им обязательств по договору.', size: 11, align: :justify
    pdf.text '2.8.2. Посещать занятия, указанные в учебном расписании, своевременно выполнять все требования учебного плана.', size: 11, align: :justify
    pdf.text '2.8.3. Соблюдать требования Устава Исполнителя, Правил внутреннего распорядка и иных локальных нормативных актов, соблюдать учебную дисциплину и общепринятые нормы поведения, в частности проявлять уважение к научно-педагогическому, инженерно-техническому, административно-хозяйственному, учебно-вспомогательному и иному персоналу Исполнителя и другим обучающимся, не посягать на их честь и достоинство.', size: 11, align: :justify
    pdf.text '2.8.4. Бережно относиться к имуществу Исполнителя.', size: 11, align: :justify
    pdf.text '2.8.5. В течение недели с момента прекращения действия настоящего Договора освободить место, занимаемое в общежитии, если соглашением сторон не предусмотрено иное.', size: 11, align: :justify
    pdf.text '2.8.6. Извещать Исполнителя об уважительных причинах отсутствия на занятиях.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'III. СТОИМОСТЬ ОБРАЗОВАТЕЛЬНЫХ УСЛУГ, СРОКИ И ПОРЯДОК ИХ ОПЛАТЫ', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text "3.1. Полная стоимость образовательных услуг за весь период обучения Обучающегося составляет #{total_fee} рублей.", size: 11, align: :justify
    pdf.text "Стоимость за первый год обучения на момент заключения настоящего Договора составляет #{first_year_fee} рублей.", size: 11, align: :justify
    pdf.text 'Увеличение стоимости образовательных услуг после заключения настоящего Договора не допускается, за исключением увеличения стоимости указанных услуг с учетом уровня инфляции, предусмотренного основными характеристиками федерального бюджета на очередной финансовый год и плановый период.', size: 11, align: :justify
    pdf.text 'Стоимость обучения в последующие годы устанавливается Исполнителем ежегодно на основании решения Ученого совета Исполнителя и доводится до сведения Обучающегося не позднее «30» июня текущего года путем размещения информации на официальном сайте Исполнителя.', size: 11, align: :justify
    pdf.text '3.2. Ежегодно плата за обучение вносится Заказчиком и (или) Обучающимся за наличный расчет или безналичный расчет в кассу Исполнителя, либо в безналичном порядке - на расчетный счет Исполнителя в срок – до 25 сентября.', size: 11, align: :justify
    pdf.text 'Допускается посеместровая оплата обучения. В этом случае сумма предоплаты за каждый семестр составляет 50% от годичной стоимости обучения, а сроки оплаты устанавливаются: до 25 сентября и 25 февраля.', size: 11, align: :justify
    pdf.text '3.3. В случае использования Обучающимся академического отпуска плата за обучение за период нахождения в отпуске не взимается, а уплаченные ранее суммы учитываются в счет погашения стоимости обучения после выхода Обучающегося из отпуска или возвращаются Заказчику. По окончании академического отпуска Заказчик в течение двух недель соразмерно оплачивает оставшуюся часть учебного года с того момента, когда Обучающийся приступил к занятиям.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'IV. ПОРЯДОК ИЗМЕНЕНИЯ И РАСТОРЖЕНИЯ ДОГОВОРА', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text '4.1. Условия, на которых заключен настоящий Договор, могут быть изменены по соглашению Сторон или в соответствии с законодательством Российской Федерации.', size: 11, align: :justify
    pdf.text '4.2. Настоящий Договор может быть расторгнут по соглашению Сторон.', size: 11, align: :justify
    pdf.text '4.3. Настоящий Договор может быть расторгнут по инициативе Исполнителя в одностороннем порядке в случаях, предусмотренных пунктом 21 Правил оказания платных образовательных услуг, утвержденных постановлением Правительства Российской Федерации от 15 августа 2013 г. N 706 (Собрание законодательства Российской Федерации, 2013, N 34, ст. 4437).', size: 11, align: :justify
    pdf.text '4.4. Действие настоящего Договора прекращается досрочно:', size: 11, align: :justify
    if campaign.campaign_type_id == 1
      pdf.text 'по инициативе Обучающегося или родителей (законных представителей) несовершеннолетнего Обучающегося, в том числе в случае перевода Обучающегося для продолжения освоения образовательной программы в другую организацию, осуществляющую образовательную деятельность;', size: 11, align: :justify
    end
    if campaign.campaign_type_id == 4
      pdf.text 'по инициативе Обучающегося, в том числе в случае перевода Обучающегося для продолжения освоения образовательной программы в другую организацию, осуществляющую образовательную деятельность;', size: 11, align: :justify
    end
    pdf.text 'по инициативе Исполнителя в случае просрочки оплаты стоимости платных образовательных услуг, в случае, если надлежащее исполнение обязательства по оказанию платных образовательных услуг стало невозможным вследствие действий (бездействия) обучающегося, в случае применения к Обучающемуся, достигшему возраста пятнадцати лет, отчисления как меры дисциплинарного взыскания, в случае невыполнения Обучающимся по профессиональной образовательной программе обязанностей по добросовестному освоению такой образовательной программы и выполнению учебного плана, а также в случае установления нарушения порядка приема в образовательную организацию, повлекшего по вине Обучающегося его незаконное зачисление в образовательную организацию;', size: 11, align: :justify
    if campaign.campaign_type_id == 1
      pdf.text 'по обстоятельствам, не зависящим от воли Обучающегося или родителей (законных представителей) несовершеннолетнего Обучающегося и Исполнителя, в том числе в случае ликвидации Исполнителя.', size: 11, align: :justify
    end
    if campaign.campaign_type_id == 4
      pdf.text 'по обстоятельствам, не зависящим от воли Обучающегося и Исполнителя, в том числе в случае ликвидации Исполнителя.', size: 11, align: :justify
    end
    pdf.text '4.5. Исполнитель вправе отказаться от исполнения обязательств по Договору при условии полного возмещения Обучающемуся убытков.', size: 11
    pdf.text '4.6. Обучающийся вправе отказаться от исполнения настоящего Договора при условии оплаты Исполнителю фактически понесенных им расходов.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'V. ОТВЕТСТВЕННОСТЬ ИСПОЛНИТЕЛЯ, ЗАКАЗЧИКА И ОБУЧАЮЩЕГОСЯ', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text '5.1. За неисполнение или ненадлежащее исполнение своих обязательств по Договору Стороны несут ответственность, предусмотренную законодательством Российской Федерации и настоящим Договором.', size: 11, align: :justify
    pdf.text '5.2. При обнаружении недостатка образовательной услуги, в том числе оказания не в полном объеме, предусмотренном образовательными программами (частью образовательной программы), Заказчик вправе по своему выбору потребовать:', size: 11, align: :justify
    pdf.text '5.2.1. Безвозмездного оказания образовательной услуги.', size: 11, align: :justify
    pdf.text '5.2.2. Соразмерного уменьшения стоимости оказанной образовательной услуги.', size: 11, align: :justify
    pdf.text '5.2.3. Возмещения понесенных им расходов по устранению недостатков оказанной образовательной услуги своими силами или третьими лицами.', size: 11, align: :justify
    pdf.text '5.3. Заказчик вправе отказаться от исполнения Договора и потребовать полного возмещения убытков, если в месячный срок с момента обращения об устранении недостатков образовательной услуги, таковые не были устранены Исполнителем. Заказчик также вправе отказаться от исполнения Договора, если им обнаружен существенный недостаток оказанной образовательной услуги, или иные существенные отступления от условий Договора.', size: 11, align: :justify
    pdf.text '5.4. Если Исполнитель нарушил сроки оказания образовательной услуги (сроки начала и (или) окончания оказания образовательной услуги и (или) промежуточные сроки оказания образовательной услуги) либо если во время оказания образовательной услуги стало очевидным, что она не будет оказана в срок, Заказчик вправе по своему выбору:', size: 11, align: :justify
    pdf.text '5.4.1. Назначить Исполнителю новый срок, в течение которого Исполнитель должен приступить к оказанию образовательной услуги и (или) закончить оказание образовательной услуги;', size: 11, align: :justify
    pdf.text '5.4.2. Поручить оказать образовательную услугу третьим лицам за разумную цену и потребовать от Исполнителя возмещения понесенных расходов;', size: 11, align: :justify
    pdf.text '5.4.3. Потребовать уменьшения стоимости образовательной услуги;', size: 11, align: :justify
    pdf.text '5.4.4. Расторгнуть Договор.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'VI. СРОК ДЕЙСТВИЯ ДОГОВОРА', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text '6.1. Настоящий Договор вступает в силу со дня его заключения Сторонами и действует до полного исполнения Сторонами обязательств.', size: 11, align: :justify
    pdf.text '6.1.1. Настоящий Договор и дополнительные соглашения к нему могут быть подписаны Сторонами путем обмена их сканированными подписанными копиями по электронной почте указанными в настоящем Договоре.', size: 11, align: :justify
    pdf.text '6.1.2. Стороны, безусловно, признают экземпляры Договора, переданные по электронной почте, равными по юридической силе экземплярам Договора с оригинальной подписью и печатью до получения оригиналов, предоставление которых Заказчиком и (или) Обучающимся обязательно в срок, установленный п. 2.7.1. настоящего Договора.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'VII. ЗАКЛЮЧИТЕЛЬНЫЕ ПОЛОЖЕНИЯ', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.text '7.1. Исполнитель вправе снизить стоимость платной образовательной услуги по Договору Обучающемуся, достигшему успехов в учебе и (или) научной деятельности, а также нуждающемуся в социальной помощи. Основания и порядок снижения стоимости платной образовательной услуги устанавливаются локальным нормативным актом Исполнителя и доводятся до сведения Обучающегося.', size: 11, align: :justify
    pdf.text '7.2. Сведения, указанные в настоящем Договоре, соответствуют информации, размещенной на официальном сайте Исполнителя в сети "Интернет" на дату заключения настоящего Договора.', size: 11, align: :justify
    pdf.text '7.3. Под периодом предоставления образовательной услуги (периодом обучения) понимается промежуток времени с даты издания приказа о зачислении Обучающегося в образовательную организацию до даты издания приказа об окончании обучения или отчислении Обучающегося из образовательной организации.', size: 11, align: :justify
    pdf.text "7.4. Настоящий Договор составлен в #{selfcontragent ? 2 : 3} экземплярах, по одному для каждой из сторон. Все экземпляры имеют одинаковую юридическую силу. Изменения и дополнения настоящего Договора могут производиться только в письменной форме и подписываться уполномоченными представителями Сторон.", size: 11, align: :justify
    pdf.text '7.5. Изменения Договора оформляются дополнительными соглашениями к Договору.', size: 11, align: :justify
    pdf.move_down 6
    pdf.text 'VIII. АДРЕСА И РЕКВИЗИТЫ СТОРОН', style: :bold, size: 11, align: :center
    pdf.move_down 6
    pdf.define_grid(columns: 3, rows: 8)
    pdf.grid([1, 0], [4, 0]).bounding_box do
      pdf.text 'Исполнитель', style: :bold, size: 11, align: :center
      pdf.text 'ФГБОУ ВО ИвГМА Минздрава России', style: :bold, size: 11, align: :center
      pdf.text 'Адрес: 153012 г. Иваново, пр.Шереметевский, 8', size: 11
      pdf.text 'тел.: (4932) 30-17-66, факс 32-66-04', size: 11
      pdf.text 'Электронная почта: contract@isma.ivanovo.ru', size: 11
      pdf.text 'ИНН 3728012776   КПП 370201001', size: 11
      pdf.text 'Получатель:  УФК по Ивановской области (ФГБОУ ВО ИвГМА Минздрава России, л/сч 20336У53600)', size: 11
      pdf.text 'Номер казначейского счета: 03214643000000013300', size: 11
      pdf.text 'БИК ТОФК: 012406500', size: 11
      pdf.text 'ЕКС: 40102810645370000025', size: 11
      pdf.text 'Наименование банка: ОТДЕЛЕНИЕ ИВАНОВО БАНКА РОССИИ//УФК ПО ИВАНОВСКОЙ ОБЛАСТИ, г. Иваново', size: 11
      pdf.text 'ОКАТО 24401364000', size: 11
      pdf.text 'ОКТМО 24701000', size: 11
      pdf.text 'КБК 00000000000000000130', size: 11
      if campaign.campaign_type_id == 1
        pdf.text 'и. о. ректора', size: 11
        pdf.move_down 20
        pdf.text '_____________ /Борзов Е. В./', size: 11
      end
      if campaign.campaign_type_id == 4
        pdf.text 'и. о. проректора по последипломному образованию и клинической работе', size: 11
        pdf.move_down 20
        pdf.text '_____________ /Полозов В. В./', size: 11
      end
      pdf.move_down 20
      pdf.text 'М.П.', size: 11
      pdf.stroke_bounds
    end
    pdf.grid([1, 1], [4, 1]).bounding_box do
      if selfcontragent 
        pdf.text 'Заказчик и Обучающийся', style: :bold, size: 11, align: :center
      else
        pdf.text 'Заказчик', style: :bold, size: 11, align: :center
      end
      pdf.text "Ф.И.О. #{contragent.fio}", size: 11
      pdf.text "Дата рождения #{contragent.birth_date.strftime("%d.%m.%Y")}", size: 11
      pdf.text "Адрес #{contragent.address}", size: 11
      pdf.text "Паспорт #{contragent.identity_document_data}", size: 11
      pdf.text "Электронная почта: #{contragent.email}", size: 11
      pdf.text "Телефон: #{contragent.phone}", size: 11
      pdf.move_down 20
      pdf.text 'Подпись _____________', size: 11
      pdf.stroke_bounds
    end
    pdf.grid([1, 2], [4, 2]).bounding_box do
      unless selfcontragent
        pdf.text 'Обучающийся', style: :bold, size: 11, align: :center
        pdf.text "Ф.И.О. #{fio}", size: 11
        pdf.text "Дата рождения #{birth_date.strftime("%d.%m.%Y")}", size: 11
        pdf.text "Адрес #{verified_address ? verified_address : address}", size: 11
        pdf.text "Паспорт #{current_identity_document.identity_document_data}", size: 11
        pdf.text "Электронная почта: #{email}", size: 11
        pdf.text "Телефон: #{phone}", size: 11
        pdf.move_down 20
        pdf.text 'Подпись _____________', size: 11
      end
      pdf.stroke_bounds
    end

    pdf.render_file tempfile

    attachment = attachments.where(document_type: 'contract', document_id: competitive_group.id, template: true).first || Attachment.new
    attachment.entrant_application_id = id
    attachment.document_type = 'contract'
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
end
