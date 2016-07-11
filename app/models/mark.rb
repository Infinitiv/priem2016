class Mark < ActiveRecord::Base
  belongs_to :subject
  belongs_to :application
  has_many :competitions, through: :application
  
  
  def self.import_from_row(row, application)
    accessible_attributes = column_names + ["chemistry_form", "biology_form", "russian_form"]
    marks = application.marks
    row_marks = row.to_hash.slice(*accessible_attributes)
    chemistry = marks.find_by_subject_id(11) || application.marks.new
    chemistry.subject_id = 11
    chemistry.value = row_marks['chemistry'].to_i
    chemistry.form = row_marks['chemistry_form']
    chemistry.save!          
    biology = marks.find_by_subject_id(4) || application.marks.new
    biology.subject_id = 4
    biology.value = row_marks['biology'].to_i
    biology.form = row_marks['biology_form']
    biology.save!
    russian = marks.find_by_subject_id(1) || application.marks.new
    russian.subject_id = 1
    russian.value = row_marks['russian'].to_i
    russian.form = row_marks['russian_form']
    russian.save! 
  end
end
