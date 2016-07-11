#encoding: utf-8
class IdentityDocument < ActiveRecord::Base
  belongs_to :identity_document_type
  belongs_to :application
  
    def self.import_from_row(row, application)
    accessible_attributes = column_names
    identity_document = application.identity_document || new
    identity_document.attributes = row.to_hash.slice(*accessible_attributes)
    identity_document.application_id = application.id
    identity_document.save!
  end

  def identity_document_data
    "Серия #{identity_document_series} номер #{identity_document_number}, выдан #{identity_document_date}"
  end
  
  def sn
    [identity_document_series, identity_document_number].compact.join('')
  end
end
