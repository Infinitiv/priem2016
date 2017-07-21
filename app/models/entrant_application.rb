class EntrantApplication < ActiveRecord::Base
  belongs_to :campaign
  has_many :marks, dependent: :destroy
  has_many :subjects, through: :marks
  has_one :education_document, dependent: :destroy
  has_and_belongs_to_many :identity_documents, dependent: :destroy
  has_and_belongs_to_many :institution_achievements
  has_many :benefit_documents, dependent: :destroy
  has_and_belongs_to_many :competitive_groups
  belongs_to :target_organization
  
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
      if entrant_application.save!
        IdentityDocument.import_from_row(row, entrant_application) if row.keys.include? 'identity_document_type'
        EducationDocument.import_from_row(row, entrant_application) if row.keys.include? 'education_document_type'
        BenefitDocument.import_from_row(row, entrant_application) if row.keys.include? 'benefit_document_type_id'
        Mark.import_from_row(row, entrant_application) if row.keys.include?('chemistry') || row.keys.include?('biology') || row.keys.include?('russian')
        InstitutionAchievement.import_from_row(row, entrant_application) if row.keys.include?('achievement_att') || row.keys.include?('achievement_dip') || row.keys.include?('achievement_gto')
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
  
  def summa
    marks.sum(:value)
  end
  
  def achiev_summa
    institution_achievements.sum(:max_value) < 10 ? institution_achievements.sum(:max_value) : 10    
  end
  
  def rank(entrant_application, competitive_group)
    campaign_id = entrant_application.campaign_id
    summa = entrant_application.summa + entrant_application.achiev_summa
    entrant_applications = EntrantApplication.where(campaign_id: campaign_id).joins(:competitive_groups).where(competitive_groups: {id: competitive_group.id}).map(&:id)
    original_entrant_applications = EntrantApplication.where(campaign_id: campaign_id).joins(:competitive_groups, :education_document).where(competitive_groups: {id: competitive_group.id}).where.not(education_documents: {original_received_date: nil}).map(&:id)
    entrant_application.education_document.original_received_date ? " (место в конкурсе - #{rank_all(campaign_id, summa, entrant_applications)}, с учетом оригиналов - #{rank_all(campaign_id, summa, original_entrant_applications)})" : " (место в конкурсе - #{rank_all(campaign_id, summa, entrant_applications)})"
  end
  
  def rank_target(entrant_application, competitive_group)
    campaign_id = entrant_application.campaign_id
    summa = entrant_application.summa + entrant_application.achiev_summa
    entrant_applications = EntrantApplication.where(campaign_id: campaign_id).joins(:competitive_groups).where(competitive_groups: {id: competitive_group.id}, target_organization_id: entrant_application.target_organization_id).map(&:id)
    " (место в конкурсе - #{rank_all(campaign_id, summa, entrant_applications)}). Всего мест в конкурсе - #{competitive_group.target_numbers.find_by_target_organization_id(entrant_application.target_organization_id).number_target_o}"
  end
  
  def rank_all(campaign_id, summa, entrant_applications)
    achievements = {}
    InstitutionAchievement.all.each do |i|
      i.entrant_applications.each do |a|
        achievements[a.id] =+ i.max_value
        achievements[a.id] = 10 if achievements[a.id] > 10
      end
    end

    marks = campaign.marks.joins(:entrant_application).where(entrant_application_id: entrant_applications).select(:entrant_application_id, :value).group_by(&:entrant_application_id).select{|a, ms| ms.select{|m| m.value > 37}.size == 3}.map{|a, ms| achievements[a] ? {a => ms.map(&:value).sum + 10} : {a => ms.map(&:value).sum}}.inject(:merge).values.sort.reverse
    marks_count = marks.count{|x| x == summa}
    marks_count > 1 ? "#{marks.index(summa) + 1}-#{marks.index(summa) + 1 + marks_count}" : marks.index(summa) + 1
  end
  
  def rank_original_only(campaign_id, summa, applications)
    marks = Mark.joins(:competitions).where(competitions: {competition_item_id: competition_item_id}, applications: {campaign_id: campaign_id}).where.not(applications: {original_received_date: nil}).group_by(&:application_id).map{|a, ms| applications.include?(a) ? ms.map{|m| m.value}.sum + 10 : ms.map{|m| m.value}.sum}.sort.reverse
    marks_count = marks.count{|x| x == summa}
    marks_count > 1 ? "#{marks.index(summa) + 1}-#{marks.index(summa) + 1 + marks_count}" : marks.index(summa) + 1
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
   applications .joins(:competitive_groups).where(competitive_groups: {education_source_id: 16}).select{|a| a.competitive_groups.find_by_education_source_id(16).id != a.budget_agr}
  end
  
  def self.admission_volume_hash(campaign)
    admission_volume_hash = {}
    campaign.competitive_groups.includes(:competitive_group_item).group_by(&:direction_id).each do |k, v|
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
  
  def self.applications_hash(campaign)
    applications_hash = {}
    applications = campaign.entrant_applications.includes(:competitive_groups, :education_document).where.not(status_id: 6)
    achievements = {}
    campaign.institution_achievements.each do |i|
      i.entrant_applications.each do |a|
        achievements[a.id] ||= 0
        achievements[a.id] += i.max_value
        achievements[a.id] = 10 if achievements[a.id] > 10
      end
    end

    marks = campaign.marks.order(:subject_id).joins(:entrant_application).where(entrant_application_id: applications).select(:entrant_application_id, :value).group_by(&:entrant_application_id).select{|a, ms| ms.select{|m| m.value > 37}.size == 3}.map{|a, ms| achievements[a] ? {a => ms.map(&:value) << achievements[a]} : {a => ms.map(&:value)}}.inject(:merge)
    applications.each do |application|
      if marks[application.id]
      applications_hash[application] = {}
      applications_hash[application][:competitive_groups] = application.competitive_groups.map(&:id)
      applications_hash[application][:russian] = marks[application.id][0]
      applications_hash[application][:biology] = marks[application.id][1]
      applications_hash[application][:chemistry] = marks[application.id][2]
      applications_hash[application][:achievement] = marks[application.id][3]
      applications_hash[application][:summa] = marks[application.id][0..2].sum
      applications_hash[application][:full_summa] = marks[application.id].sum
      applications_hash[application][:original_received] = application.education_document.original_received_date ? true : false
      applications_hash[application][:budget_agr] = application.budget_agr
      applications_hash[application][:paid_agr] = application.paid_agr
      end
    end
    applications_hash = applications_hash.sort_by{|k, v| [v[:full_summa], v[:summa], v[:chemistry], v[:biology], v[:russian]]}.reverse
  end
end
