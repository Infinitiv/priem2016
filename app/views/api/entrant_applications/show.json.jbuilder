json.entrant_application @entrant_application, :id, :application_number, :campaign_id, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :benefit, :olympionic, :budget_agr, :paid_agr, :status_id, :comment, :status, :request, :enrolled, :enrolled_date

unless @entrant_application.marks.empty?
  json.marks @entrant_application.marks.includes(:subject) do |mark|
    json.id mark.id
    json.value mark.value
    json.subject mark.subject.subject_name
    json.form mark.form
    json.checked mark.checked
    json.organization_uid mark.organization_uid
  end
end

unless @entrant_application.achievements.empty?
  json.achievements @entrant_application.achievements do |achievement|
    json.id achievement.id
    json.name achievement.institution_achievement.name
    json.value achievement.value
    json.status achievement.status
  end
end

json.sum @sum
json.achievements_sum @achievements_sum
json.full_sum @full_sum

json.identity_documents @entrant_application.identity_documents.order(:identity_document_date), :id, :identity_document_type, :identity_document_series, :identity_document_number, :identity_document_date, :identity_document_issuer, :status, :identity_document_data

if @entrant_application.education_document
  json.education_document @entrant_application.education_document, :id, :education_document_type, :education_document_number, :education_document_date, :education_document_issuer, :original_received_date, :education_speciality_code, :status
end

json.olympic_documents @entrant_application.olympic_documents, :id, :benefit_type_id, :olympic_id, :diploma_type_id, :olympic_profile_id, :class_number, :olympic_document_series, :olympic_document_number, :olympic_document_date, :olympic_subject_id, :ege_subject_id, :status, :olympic_document_type_id

json.benefit_documents @entrant_application.benefit_documents, :id, :benefit_document_type_id, :benefit_document_series, :benefit_document_number, :benefit_document_date, :benefit_document_organization, :benefit_type_id, :status

json.other_documents @entrant_application.other_documents, :id, :other_document_series, :other_document_number, :other_document_number, :other_document_issuer, :name

json.competitive_groups @entrant_application.competitive_groups.order(:name), :id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id

unless @entrant_application.target_contracts.empty?
  json.target_contracts @entrant_application.target_contracts do |target_contract|
    json.id target_contract.id
    json.competitive_group_name target_contract.competitive_group.name
    json.target_organization_name target_contract.target_organization.target_organization_name
    json.status target_contract.status
  end
end

json.contracts @entrant_application.contracts, :competitive_group_id, :status

json.attachments @entrant_application.attachments, :id, :document_type, :mime_type, :data_hash, :status, :merged, :template, :document_id, :filename
