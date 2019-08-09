json.array! @entrants do |entrant|
  json.application_number entrant.application_number
  json.gender_id entrant.gender_id
  json.birth_date entrant.birth_date
  json.region_id entrant.region_id
  json.registration_date entrant.registration_date
  json.status_id entrant.status_id
  json.nationality_type_id entrant.nationality_type_id
  json.enrolled entrant.enrolled
  json.enrolled_date entrant.enrolled_date
  json.exeptioned entrant.exeptioned
  json.exeptioned_date entrant.exeptioned_date
  json.return_documents_date entrant.return_documents_date
  json.enrolled_name entrant.competitive_groups.find(entrant.enrolled).name if entrant.enrolled
  json.exeptioned_name entrant.competitive_groups.find(entrant.exeptioned).name if entrant.exeptioned
  olympics = entrant.olympic_documents
  unless olympics.empty?
    olympic_type = olympics.map(&:benefit_type_id).include?(2) ? 'Без ВИ' : 'ЕГЭ 100'
  end
  json.olympic_type olympic_type if olympic_type
  marks = entrant.marks
  if olympic_type == 'ЕГЭ 100'
    olympics.each do |olympic|
      marks.where(subject_id: olympic.ege_subject_id).update_all(form: 'Олимпиада')
    end
  end
  ege_count = marks.map(&:form).count('ЕГЭ')
  json.ege_count ege_count
  json.sum marks.sum(:value)
  exam_category = case ege_count
  when 0
    'ВИ'
  when 3
    'ЕГЭ'
  else
    'смешанный'
  end
  json.exam_category exam_category
  json.mean_ege marks.where(form: 'ЕГЭ').sum(:value).to_f / marks.where(form: 'ЕГЭ').count if marks.where(form: 'ЕГЭ').count > 0
  json.mean_exam marks.where(form: 'Экзамен').sum(:value).to_f / marks.where(form: 'Экзамен').count if marks.where(form: 'Экзамен').count > 0
  achievements = entrant.achievements
  json.achievements achievements.sum(:value) > 10 ? 10.to_f : achievements.sum(:value)
  benefits = entrant.benefit_documents
  unless benefits.empty?
    if benefits.map(&:benefit_type_id).include?(4)
      benefit_type = 'Особая квота'
      benefit_document_type = case true
      when benefits.map(&:benefit_document_type_id).include?(11)
        'Ивалид'
      when benefits.map(&:benefit_document_type_id).include?(30)
        'Сирота'
      end
    else 
      benefit_type = 'Премущественное право'
    end
  end
  json.benefit_type benefit_type if benefit_type
  json.benefit_document_type benefit_document_type if benefit_document_type
end
