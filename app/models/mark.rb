class Mark < ActiveRecord::Base
  belongs_to :subject
  belongs_to :entrant_application
  has_many :competitions, through: :entrant_application
  
  
  def self.import_from_row(row, entrant_applicaton)
    marks = entrant_applicaton.marks
    chemistry = marks.find_by_subject_id(3) || entrant_applicaton.marks.new
    chemistry.subject_id = 3
    chemistry.value = row['chemistry'].to_i
    chemistry.form = row['chemistry_form']
    chemistry.save!     
    biology = marks.find_by_subject_id(2) || entrant_applicaton.marks.new
    biology.subject_id = 2
    biology.value = row['biology'].to_i
    biology.form = row['biology_form']
    biology.save!
    russian = marks.find_by_subject_id(1) || entrant_applicaton.marks.new
    russian.subject_id = 1
    russian.value = row['russian'].to_i
    russian.form = row['russian_form']
    russian.save!
  end
end
