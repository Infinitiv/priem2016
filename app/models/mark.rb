class Mark < ActiveRecord::Base
  belongs_to :subject
  belongs_to :entrant_application
  has_many :competitions, through: :entrant_application  
  
  def self.import_from_row(row, entrant_application)
    marks = entrant_application.marks
    case true
    when entrant_application.campaign.education_levels.include?(5)
      chemistry = marks.find_by_subject_id(3) || entrant_application.marks.new
      chemistry.subject_id = 3
      chemistry.value = row['chemistry'].to_i if row['chemistry']
      chemistry.form = row['chemistry_form'] if row['chemistry_form']
      chemistry.save!
      biology = marks.find_by_subject_id(2) || entrant_application.marks.new
      biology.subject_id = 2
      biology.value = row['biology'].to_i if row['biology']
      biology.form = row['biology_form'] if row['biology_form']
      biology.save!
      russian = marks.find_by_subject_id(1) || entrant_application.marks.new
      russian.subject_id = 1
      russian.value = row['russian'].to_i if row['russian']
      russian.form = row['russian_form'] if row['russian_form']
      russian.save!
    when entrant_application.campaign.education_levels.include?(18)
      test_result = marks.find_by_subject_id(4) || entrant_application.marks.new
      test_result.subject_id = 4
      test_result.value = row['test_result'].to_i
      test_result.form = row['test_form'] if row['test_form']
      test_result.organization_uid = row['organization_uid'] if row['organization_uid']
      test_result.checked = Time.now
      test_result.save!
    end
  end
end
