class EntrantApplication < ActiveRecord::Base
  belongs_to :campaign
  has_many :marks
  has_one :education_document
  has_many :identity_documents
  has_and_belongs_to_many :institution_achievements
  has_and_belongs_to_many :competitive_groups
  
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
    accessible_attributes = column_names
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).to_a.in_groups_of(100, false) do |group|
      ActiveRecord::Base.transaction do
        group.each do |i|
          row = Hash[[header, spreadsheet.row(i)].transpose]
          entrant_application = where(application_number: row["application_number"], campaign_id: campaign).first || new
          entrant_application.attributes = row.to_hash.slice(*accessible_attributes)
          entrant_application.campaign_id = campaign.id
          if entrant_application.save!
#             IdentityDocument.import_from_row(row, entrant_application)
             EducationDocument.import_from_row(row, entrant_application)
#             Competition.import_from_row(row, entrant_application)
             Mark.import_from_row(row, entrant_application)
#             case row["achievement"]
#             when 'TRUE'
#               entrant_application.institution_achievements << achievement_attestat unless entrant_application.institution_achievements.include?(achievement_attestat)
#             else
#               entrant_application.institution_achievements.delete(achievement_attestat)
#             end
          end
        end
      end
    end
  end 
  
end
