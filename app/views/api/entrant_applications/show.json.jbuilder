json.entrant_application @entrant_application, :id, :application_number, :campaign_id, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :benefit, :olympionic, :budget_agr, :paid_agr, :status_id, :comment, :status, :request, :enrolled, :enrolled_date

json.marks @entrant_application.marks.includes(:subject) do |mark|
  json.id mark.id
  json.value mark.value
  json.subject mark.subject.subject_name
  json.form mark.form
  json.checked mark.checked
  json.organization_uid mark.organization_uid
end

json.achievements @entrant_application.achievements do |achievement|
  json.id achievement.id
  json.name achievement.institution_achievement.name
  json.value achievement.value
  json.status achievement.status
end

json.sum @sum
json.achievements_sum @achievements_sum
json.full_sum @full_sum

json.identity_documents @entrant_application.identity_documents.order(:identity_document_date) do |identity_document|
  json.id identity_document.id
  json.identity_document_type identity_document.identity_document_type
  json.identity_document_data identity_document.identity_document_data
  json.status identity_document.status
end

json.education_document do
  json.id @entrant_application.education_document.id
  json.education_document_type @entrant_application.education_document.education_document_type
  json.education_document_data @entrant_application.education_document.education_document_data
  json.education_speciality_code @entrant_application.education_document.education_speciality_code
  json.status @entrant_application.education_document.status
end

json.olympic_documents @entrant_application.olympic_documents do |olympic_document|
  json.id olympic_document.id
  json.olympic_document_data olympic_document.olympic_document_data
  json.status olympic_document.status
end

json.benefit_documents @entrant_application.benefit_documents do |benefit_document|
  json.id benefit_document.id
  json.benefit_document_data benefit_document.benefit_document_data
  json.status benefit_document.status
end

json.other_documents @entrant_application.other_documents do |other_document|
  json.id other_document.id
  json.other_document_data other_document.other_document_data
end

json.competitive_groups @entrant_application.competitive_groups.order(:name), :id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id

json.target_contracts @entrant_application.target_contracts do |target_contract|
  json.id target_contract.id
  json.competitive_group_name target_contract.competitive_group.name
  json.target_organization_name target_contract.target_organization.target_organization_name
  json.status target_contract.status
end

json.contracts @entrant_application.contracts, :competitive_group_id, :status

json.attachments @entrant_application.attachments, :id, :document_type, :mime_type, :data_hash, :status, :merged, :template, :document_id, :filename
