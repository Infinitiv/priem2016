json.array! @entrant_applications do |entrant_application|
  json.entrant_application_region_id entrant_application.region_id
  json.entrant_application_enrolled entrant_application.enrolled
  json.education_document entrant_application.education_document, :education_document_type, :education_document_date, :original_received_date
end
