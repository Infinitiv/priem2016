class OlympicDocument < ActiveRecord::Base
  belongs_to :entrant_application
  
  def self.import_from_row(row, entrant_application)
    accessible_attributes = column_names
    olympic_document = entrant_application.olympic_documents.where(olympic_document_series: row['olympic_document_series'], olympic_document_number: row['olympic_document_number']).first || entrant_application.olympic_documents.new
    olympic_document.attributes = row.to_hash.slice(*accessible_attributes)
    olympic_document.save!
  end
  
  def olympic_document_data
    "Серия #{olympic_document_series} номер #{olympic_document_number}"
  end
end
