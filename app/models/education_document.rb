#encoding: utf-8
class EducationDocument < ActiveRecord::Base
  belongs_to :entrant_application
  
  def self.import_from_row(row, entrant_application)
    accessible_attributes = column_names
    education_document = entrant_application.education_document || new
    education_document.attributes = row.to_hash.slice(*accessible_attributes)
    education_document.entrant_application_id = entrant_application.id
    education_document.save!
  end

  def education_document_data
    "Номер #{education_document_number}, выдан #{education_document_date}"
  end
end
