class OtherDocument < ActiveRecord::Base
  belongs_to :entrant_application
  belongs_to :attachment
  
  def other_document_data
    "#{name} Серия #{other_document_series} номер #{other_document_number}, выдан #{other_document_date.strftime("%d.%m.%Y") if other_document_date} #{other_document_issuer}"
  end
end
