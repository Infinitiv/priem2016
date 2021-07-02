json.entrant_application do
  json.id @entrant_application.id
  json.application_number @entrant_application.application_number
  json.registration_number @entrant_application.registration_number
  json.campaign_id @entrant_application.campaign_id
  json.nationality_type_id @entrant_application.nationality_type_id
  json.personal do
    json.entrant_last_name @entrant_application.entrant_last_name ? @entrant_application.entrant_last_name : ''
    json.entrant_first_name @entrant_application.entrant_first_name ? @entrant_application.entrant_first_name : ''
    json.entrant_middle_name @entrant_application.entrant_middle_name ? @entrant_application.entrant_middle_name : ''
    json.gender_id @entrant_application.gender_id
    json.birth_date @entrant_application.birth_date ? @entrant_application.birth_date : ''
  end
  json.contact_information do
    json.address @entrant_application.verified_address ? @entrant_application.verified_address : @entrant_application.address
    json.zip_code @entrant_application.zip_code
    json.email @entrant_application.email
    json.phone @entrant_application.phone
  end
  json.benefit @entrant_application.benefit
  json.olympionic @entrant_application.olympionic
  json.budget_agr @entrant_application.budget_agr
  json.paid_agr @entrant_application.paid_agr
  json.status_id @entrant_application.status_id
  json.comment @entrant_application.comment
  json.status @entrant_application.status
  json.request @entrant_application.request
  json.enrolled @entrant_application.enrolled
  json.enrolled_date @entrant_application.enrolled_date
  json.need_hostel @entrant_application.need_hostel
  json.special_entrant @entrant_application.special_entrant
  json.special_conditions @entrant_application.special_conditions
  json.hash @entrant_application.data_hash
  json.snils @entrant_application.snils
  json.snils_absent @entrant_application.snils_absent
  json.language @entrant_application.language
  json.source @entrant_application.source
  json.clerk @entrant_application.clerk
  json.identity_documents @entrant_application.identity_documents.order(identity_document_date: :desc) do |identity_document|
    json.id identity_document.id
    json.identity_document_type identity_document.identity_document_type
    json.identity_document_series identity_document.identity_document_series
    json.identity_document_number identity_document.identity_document_number
    json.identity_document_date identity_document.identity_document_date
    json.identity_document_issuer identity_document.identity_document_issuer
    json.status identity_document.status
    json.identity_document_data identity_document.identity_document_data
    json.alt_entrant_last_name identity_document.alt_entrant_last_name
    json.alt_entrant_first_name identity_document.alt_entrant_first_name
    json.alt_entrant_middle_name identity_document.alt_entrant_middle_name
  end
  if @entrant_application.education_document
    json.education_document do
      json.id @entrant_application.education_document.id
      json.education_document_type @entrant_application.education_document.education_document_type
      json.education_document_number @entrant_application.education_document.education_document_number
      json.education_document_date @entrant_application.education_document.education_document_date
      json.education_document_issuer @entrant_application.education_document.education_document_issuer
      json.original_received_date @entrant_application.education_document.original_received_date
      json.education_speciality_code @entrant_application.education_document.education_speciality_code
      json.status @entrant_application.education_document.status
      json.is_original @entrant_application.education_document.education_document_date ? true : false
    end
  else
    json.education_document nil
  end
  json.marks @entrant_application.marks.includes(:subject) do |mark|
    json.id mark.id
    json.value mark.value
    json.subject_id mark.subject_id
    json.subject mark.subject.subject_name
    json.form mark.form
    json.year mark.year
    json.checked mark.checked
    json.organization_uid mark.organization_uid
  end
  json.sum @sum
  json.achievements_sum @achievements_sum
  json.full_sum @full_sum
  json.achievements  @entrant_application.achievements do |achievement|
    json.id achievement.id
    json.name achievement.institution_achievement.name
    json.value achievement.value
    json.status achievement.status
  end
  json.achievement_ids @entrant_application.achievements.map(&:institution_achievement_id)
  json.olympic_documents @entrant_application.olympic_documents do |olympic_document|
    json.id olympic_document.id
    json.benefit_type_id olympic_document.benefit_type_id
    json.olympic_id olympic_document.olympic_id
    json.diploma_type_id olympic_document.diploma_type_id
    json.olympic_profile_id olympic_document.olympic_profile_id
    json.class_number olympic_document.class_number
    json.olympic_document_series olympic_document.olympic_document_series
    json.olympic_document_number olympic_document.olympic_document_number
    json.olympic_document_date olympic_document.olympic_document_date
    json.olympic_subject_id olympic_document.olympic_subject_id
    json.ege_subjectId olympic_document.ege_subject_id
    json.status olympic_document.status
    json.olympic_document_type_id olympic_document.olympic_document_type_id
  end
  json.benefit_documents @entrant_application.benefit_documents do |benefit_document|
    json.id benefit_document.id
    json.benefit_document_type_id benefit_document.benefit_document_type_id
    json.benefit_document_series benefit_document.benefit_document_series
    json.benefit_document_number benefit_document.benefit_document_number
    json.benefit_document_date benefit_document.benefit_document_date
    json.benefit_document_organization benefit_document.benefit_document_organization
    json.benefit_type_id benefit_document.benefit_type_id
    json.status benefit_document.status
  end
  json.other_documents @entrant_application.other_documents do |other_document|
    json.id other_document.id
    json.other_document_series other_document.other_document_series
    json.other_document_number other_document.other_document_number
    json.other_document_date other_document.other_document_date
    json.other_document_issuer other_document.other_document_issuer
    json.name other_document.name
  end
  json.competitive_groups @entrant_application.competitive_groups.order(:name) do |competitive_group|
    json.id competitive_group.id
    json.name competitive_group.name
    json.education_level_id competitive_group.education_level_id
    json.education_source_id competitive_group.education_source_id
    json.education_form_id competitive_group.education_form_id
    json.direction_id competitive_group.direction_id
  end
  json.competitive_group_ids @entrant_application.competitive_groups.map(&:id)
  json.target_contracts @entrant_application.target_contracts do |target_contract|
    json.id target_contract.id
    json.competitive_group_id target_contract.competitive_group.id
    json.competitive_group_name target_contract.competitive_group.name
    json.target_organization_id target_contract.target_organization.id
    json.target_organization_name target_contract.target_organization.target_organization_name
    json.status target_contract.status
  end
  json.contracts @entrant_application.contracts do |contract|
    json.competitive_group_id contract.competitive_group_id
    json.competitive_group_name contract.competitive_group.name
    json.status contract.status
  end
  json.tickets @entrant_application.tickets do |ticket|
    json.id ticket.id
    json.entrant_application_id ticket.entrant_application_id
    json.parent_id ticket.parent_id
    json.message ticket.message
    json.solved ticket.solved
    json.created_at ticket.created_at
  end
  json.attachments @entrant_application.attachments do |attachment|
    json.id attachment.id
    json.document_type attachment.document_type
    json.mime_type attachment.mime_type
    json.data_hash attachment.data_hash
    json.status attachment.status
    json.merged attachment.merged
    json.template attachment.template
    json.document_id attachment.document_id
    json.filename attachment.filename
    json.created_at attachment.created_at
  end
end
