json.entrantApplication do
  json.applicationNumber @entrant_application.application_number
  json.campaignId @entrant_application.campaign_id
  json.nationalityTypeId @entrant_application.nationality_type_id
  json.personal do
    json.entrantLastName @entrant_application.entrant_last_name ? @entrant_application.entrant_last_name : ''
    json.entrantFirstName @entrant_application.entrant_first_name ? @entrant_application.entrant_first_name : ''
    json.entrantMiddleName @entrant_application.entrant_middle_name ? @entrant_application.entrant_middle_name : ''
    json.genderId @entrant_application.gender_id
    json.birthDate @entrant_application.birth_date ? @entrant_application.birth_date : ''
  end
  json.contactInformation do
    json.address @entrant_application.verified_address ? @entrant_application.verified_address : @entrant_application.address
    json.zipCode @entrant_application.zip_code
    json.email @entrant_application.email
    json.phone @entrant_application.phone
  end
  json.benefit @entrant_application.benefit
  json.olympionic @entrant_application.olympionic
  json.budgetAgr @entrant_application.budget_agr
  json.paidAgr @entrant_application.paid_agr
  json.statusId @entrant_application.status_id
  json.comment @entrant_application.comment
  json.status @entrant_application.status
  json.request @entrant_application.request
  json.enrolled @entrant_application.enrolled
  json.enrolledDate @entrant_application.enrolled_date
  json.needHostel @entrant_application.need_hostel
  json.specialEntrant @entrant_application.special_entrant
  json.specialConditions @entrant_application.special_conditions
  json.hash @entrant_application.data_hash
  json.snils @entrant_application.snils
  json.snilsAbsent @entrant_application.snils_absent
  json.identityDocuments @entrant_application.identity_documents.order(:identity_document_date) do |identity_document|
    json.id identity_document.id
    json.identityDocumentType identity_document.identity_document_type
    json.identityDocumentSeries identity_document.identity_document_series
    json.identityDocumentNumber identity_document.identity_document_number
    json.identityDocumentDate identity_document.identity_document_date
    json.identityDocumentIssuer identity_document.identity_document_issuer
    json.status identity_document.status
    json.identityDocumentData identity_document.identity_document_data
    json.altEntrantLastName identity_document.alt_entrant_last_name
    json.altEntrantFirstName identity_document.alt_entrant_first_name
    json.altEntrantMiddleName identity_document.alt_entrant_middle_name
  end
  if @entrant_application.education_document
    json.educationDocument do
      json.id @entrant_application.education_document.id
      json.educationDocumentType @entrant_application.education_document.education_document_type
      json.educationDocumentNumber @entrant_application.education_document.education_document_number
      json.educationDocumentDate @entrant_application.education_document.education_document_date
      json.educationDocumentIssuer @entrant_application.education_document.education_document_issuer
      json.originalReceivedDate @entrant_application.education_document.original_received_date
      json.educationSpecialityCode @entrant_application.education_document.education_speciality_code
      json.status @entrant_application.education_document.status
      json.isOriginal @entrant_application.education_document.education_document_date ? true : false
    end
  else
    json.educationDocument nil
  end
  json.marks @entrant_application.marks.includes(:subject) do |mark|
    json.id mark.id
    json.value mark.value
    json.subjectId mark.subject_id
    json.subject mark.subject.subject_name
    json.form mark.form
    json.checked mark.checked
    json.organizationUid mark.organization_uid
  end
  json.sum @sum
  json.achievementsSum @achievements_sum
  json.fullSum @full_sum
  json.achievements  @entrant_application.achievements do |achievement|
    json.id achievement.id
    json.name achievement.institution_achievement.name
    json.value achievement.value
    json.status achievement.status
  end
  json.olympicDocuments @entrant_application.olympic_documents do |olympic_document|
    json.id olympic_document.id
    json.benefitDocumentTypeId olympic_document.benefit_type_id
    json.olympicId olympic_document.olympic_id
    json.diplomaTypeId olympic_document.diploma_type_id
    json.olympicProfileId olympic_document.olympic_profile_id
    json.classNumber olympic_document.class_number
    json.olympicDocumentSeries olympic_document.olympic_document_series
    json.olympicDocumentNumber olympic_document.olympic_document_number
    json.olympicDocumentDate olympic_document.olympic_document_date
    json.olympicSubjectId olympic_document.olympic_subject_id
    json.ege_subjectId olympic_document.ege_subject_id
    json.status olympic_document.status
    json.olympicDocumentTypeId olympic_document.olympic_document_type_id
  end
  json.benefitDocuments @entrant_application.benefit_documents do |benefit_document|
    json.id benefit_document.id
    json.benefitDocumentTypeId benefit_document.benefit_document_type_id
    json.benefitDocumentSeries benefit_document.benefit_document_series
    json.benefitDocumentNumber benefit_document.benefit_document_number
    json.benefitDocumentDate benefit_document.benefit_document_date
    json.benefitDocumentOrganization benefit_document.benefit_document_organization
    json.benefitTypeId benefit_document.benefit_type_id
    json.status benefit_document.status
  end
  json.otherDocuments @entrant_application.other_documents do |other_document|
    json.id other_document.id
    json.otherDocumentSeries other_document.other_document_series
    json.otherDocumentNumber other_document.other_document_number
    json.otherDocumentDate other_document.other_document_date
    json.otherDocumentIssuer other_document.other_document_issuer
    json.name other_document.name
  end
  json.competitiveGroups @entrant_application.competitive_groups.order(:name) do |competitive_group|
    json.id competitive_group.id
    json.name competitive_group.name
    json.educationLevelId competitive_group.education_level_id
    json.educationSourceId competitive_group.education_source_id
    json.educationFormId competitive_group.education_form_id
    json.directionId competitive_group.direction_id
  end
  json.targetContracts @entrant_application.target_contracts do |target_contract|
    json.id target_contract.id
    json.competitiveGroupId target_contract.competitive_group.id
    json.competitiveGroupName target_contract.competitive_group.name
    json.targetOrganizationId target_contract.target_organization.id
    json.targetOrganizationName target_contract.target_organization.target_organization_name
    json.status target_contract.status
  end
  json.contracts @entrant_application.contracts do |contract|
    json.competitiveGroupId contract.competitive_group_id
    json.competitiveGroupName contract.competitive_group.name
    json.status contract.status
  end
  json.attachments @entrant_application.attachments do |attachment|
    json.id attachment.id
    json.documentType attachment.document_type
    json.mimeType attachment.mime_type
    json.dataHash attachment.data_hash
    json.status attachment.status
    json.merged attachment.merged
    json.template attachment.template
    json.documentId attachment.document_id
    json.filename attachment.filename
  end
end
