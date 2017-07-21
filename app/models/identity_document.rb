#encoding: utf-8
class IdentityDocument < ActiveRecord::Base
  has_and_belongs_to_many :entrant_application
  
  def self.import_from_row(row, entrant_application)
    accessible_attributes = column_names
    identity_document = entrant_application.identity_documents.where(identity_document_series: row['identity_document_series'], identity_document_number: row['identity_document_number']).first || entrant_application.identity_documents.new
    identity_document.attributes = row.to_hash.slice(*accessible_attributes)
    identity_document.save!
  end

  def identity_document_data
    "Серия #{identity_document_series} номер #{identity_document_number}, выдан #{identity_document_date}"
  end
  
  def sn
    [identity_document_series, identity_document_number].compact.join('')
  end
end
