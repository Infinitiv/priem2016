class BenefitDocument < ActiveRecord::Base
  belongs_to :entrant_application
  
  def self.import_from_row(row, entrant_application)
    accessible_attributes = column_names
    benefit_document = entrant_application.benefit_documents.where(benefit_document_series: row['benefit_document_series'], benefit_document_number: row['benefit_document_number']).first || entrant_application.benefit_documents.new
    benefit_document.attributes = row.to_hash.slice(*accessible_attributes)
    benefit_document.save!
  end
  
  def benefit_document_data
    "Серия #{benefit_document_series} номер #{benefit_document_number}, выдан #{benefit_document_date.strftime("%d.%m.%Y")} #{benefit_document_organization}"
  end
end
