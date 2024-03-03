@entrant_applications.each do |entrant_application|
  entrant_application_id = entrant_application.id
  education_document = entrant_application.education_document
  json.array! entrant_application.competitive_groups.each do |competitive_group|
    if @target_contracts[entrant_application_id]
      target_contract = @target_contracts[entrant_application_id].select{|tc| tc.competitive_group_id == competitive_group.id}.first
    end
    entrance_tests = competitive_group.entrance_test_items.map(&:entrance_test_priority).zip(competitive_group.entrance_test_items.map(&:subject_id)).uniq.sort_by{|k, v| [k, v]}
    test_types = []
    marks = []
    subjects = []
    entrant_actual_marks = @marks[entrant_application_id]
    entrant_actual_marks.each do |actual_mark|
        entrance_tests.each do |priority, subject|
          if subject == actual_mark.subject_id
            test_types << actual_mark.form
            marks << actual_mark.value
            subjects << actual_mark.subject.subject_name
          end
        end
    end
    
    sum_ege = 0
    test_types.each_with_index do |test_type, index|
      sum_ege += marks[index] if test_type == 'ЕГЭ'
    end
    if @achievements[entrant_application_id]
      achievements = @achievements[entrant_application_id].map(&:value) 
      achievement_types = @achievements[entrant_application_id].map(&:institution_achievement_id)
    end

    json.application_number entrant_application.application_number
    json.fio entrant_application.fio
    json.snils entrant_application.snils
    json.nationality entrant_application.nationality_type_id == 1 ? 'РОССИЯ' : entrant_application.nationality_type_id
    json.region_with_type entrant_application.region_with_type
    json.registration_date entrant_application.registration_date.to_date
    json.stage entrant_application.status_id
    json.source entrant_application.source
    json.competitive_group_name competitive_group.name
    case competitive_group.education_source_id
    when 14
      json.education_source 'Основные места в рамках КЦП'
    when 15
      json.education_source 'По договору об оказании платных образовательных услуг'
    when 16
      json.education_source 'Целевая квота'
    when 20
      json.education_source 'Особая квота'
    end
    json.enrolled_date entrant_application.enrolled == competitive_group.id ? entrant_application.enrolled_date : nil
    json.exeptioned_date entrant_application.exeptioned == competitive_group.id ? entrant_application.exeptioned_date : nil
    json.sum marks.sum
    json.achievements @institution_achievements.where(id: [achievement_types]).map(&:name).join('&')
    json.achievement_sum entrant_application.achievements.sum(:value) > 10 ? 10 : entrant_application.achievements.sum(:value)
    json.full_sum marks.sum + (entrant_application.achievements.sum(:value) > 10 ? 10 : entrant_application.achievements.sum(:value))
    case true
    when test_types.count == 0
      json.test_type nil
    when test_types.count('ЕГЭ') == test_types.length
      json.test_type 'ЕГЭ'
    when test_types.count('ЕГЭ') == 0
      json.test_type 'ВИ'
    else
      json.test_type 'ЕГЭ+ВИ'
    end
    json.test_type_1 test_types[0]
    json.test_type_2 test_types[1]
    json.test_type_3 test_types.length == 3 ? test_types[2] : nil
    json.test_subject_1 subjects[0]
    json.test_subject_2 subjects[1]
    json.test_subject_3 subjects.length == 3 ? subjects[2] : nil
    json.mark_1 marks[0]
    json.mark_2 marks[1]
    json.mark_3 test_types.length == 3 ? marks[2] : nil
    json.ege_count test_types.count('ЕГЭ')
    json.test_count test_types.count
    json.sum_ege sum_ege
    json.direction competitive_group.name.split('.').first
    json.benefit_documents @benefit_documents[entrant_application_id].map(&:benefit_type_id).join('&') if @benefit_documents[entrant_application_id]
    json.education_document education_document.education_document_type if education_document
    json.education_document_date education_document.education_document_date if education_document
    json.education_document_issuer education_document.education_document_issuer if education_document
    json.original education_document.original_received_date if education_document
    json.target_employee target_contract.target_organization.target_organization_name if target_contract
  end
end