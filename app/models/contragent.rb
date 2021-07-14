class Contragent < ActiveRecord::Base
  belongs_to :entrant_application
  
  def identity_document_data
    "Серия #{identity_document_serie} номер #{identity_document_number}, выдан #{[identity_document_issuer, (identity_document_date.strftime("%d.%m.%Y") if identity_document_date)].compact.join(' ')}"
  end
  
  def fio
    [last_name, first_name, middle_name].compact.join(' ')
  end
end
