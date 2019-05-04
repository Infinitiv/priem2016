json.entrant_application @entrant_application, :data_hash, :campaign_id, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :gender_id, :birth_date, :email, :need_hostel, :nationality_type_id, :target_organization_id, :special_entrant, :budget_agr, :paid_agr, :snils

json.marks @entrant_application.marks, :id, :value, :subject_id, :form, :checked, :organization_uid

json.identity_documents @entrant_application.identity_documents, :id, :identity_document_type, :identity_document_series, :identity_document_number, :identity_document_date, :alt_entrant_last_name, :alt_entrant_first_name, :alt_entrant_middle_name

json.education_document @entrant_application.education_document, :id, :education_document_type, :education_document_number, :education_document_date, :original_received_date, :education_speciality_code

json.achievements @entrant_application.achievements, :id, :institution_achievement_id, :value

json.olympic_documents @entrant_application.olympic_documents, :id, :benefit_type_id, :olympic_id, :diploma_type_id, :olympic_profile_id, :class_number, :olympic_document_series, :olympic_document_number, :olympic_document_date, :olympic_subject_id, :ege_subject_id

json.benefit_documents @entrant_application.benefit_documents, :id, :benefit_document_type_id, :benefit_document_series, :benefit_document_number, :benefit_document_date, :benefit_document_organization, :benefit_type_id

json.competitive_groups @entrant_application.competitive_groups, :id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id
