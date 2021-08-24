json.array! @entrants do |entrant|
  json.year entrant.campaign.year_start
  json.application_number entrant.application_number
  json.fio entrant.fio
  json.gender_id entrant.gender_id == 1 ? 'мужской' : 'женский'
  json.birth_date entrant.birth_date
  json.snils entrant.snils
  json.region_id entrant.region_id
  json.registration_date entrant.registration_date
  json.nationality @countries.select{|country| country.key(entrant.nationality_type_id)}.first['name']
  json.region_with_type entrant.region_with_type
  json.status_id entrant.status_id
  json.source entrant.source
  json.agreement entrant.budget_agr ? entrant.competitive_groups.find(entrant.budget_agr).name : nil
  json.competitive_groups entrant.competitive_groups.map(&:name).join(',')
  identity_document = entrant.identity_documents.order(identity_document_date: :desc).first
  json.identity_document_type identity_document.identity_document_type
  json.identity_document_series identity_document.identity_document_series
  json.identity_document_number identity_document.identity_document_number
  json.identity_document_issuer identity_document.identity_document_issuer
  json.identity_document_date identity_document.identity_document_date
  education_document = entrant.education_document
  json.education_document_type education_document.education_document_type
  json.education_document_date education_document.education_document_date
  json.return_documents_date entrant.return_documents_date
  json.direction entrant.enrolled ? @specialities.select{|speciality| speciality.key(entrant.competitive_groups.find(entrant.enrolled).direction_id)}.first['name'] : nil
  json.enrolled_name entrant.enrolled ? entrant.competitive_groups.find(entrant.enrolled).name : nil
  json.education_source_id entrant.enrolled ? entrant.competitive_groups.find(entrant.enrolled).education_source_id : nil
  json.enrolled_date entrant.enrolled_date
  json.exeptioned_name entrant.exeptioned ? entrant.competitive_groups.find(entrant.exeptioned).name : nil
  json.exeptioned_date entrant.exeptioned_date
  olympics = entrant.olympic_documents
  unless olympics.empty?
    olympic_type = olympics.map(&:benefit_type_id).include?(1) ? 'Без ВИ' : 'ЕГЭ 100'
  end
  json.olympic_type olympic_type ? olympic_type : nil
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
  json.mean_ege marks.where(form: 'ЕГЭ').count > 0 ? marks.where(form: 'ЕГЭ').sum(:value).to_f / marks.where(form: 'ЕГЭ').count : nil
  json.mean_exam marks.where(form: 'Экзамен').count > 0 ? marks.where(form: 'Экзамен').sum(:value).to_f / marks.where(form: 'Экзамен').count : nil
  achievements = entrant.achievements
  if entrant.campaign.campaign_type_id == 1
    json.achievements achievements.sum(:value) > 10 ? 10.to_f : achievements.sum(:value)
  else
    json.achievements achievements.sum(:value)
  end
  benefits = entrant.benefit_documents
  unless benefits.empty?
    if benefits.map(&:benefit_type_id).include?(4)
      benefit_type = 'Особая квота'
      benefit_document_type = case true
      when benefits.map(&:benefit_document_type_id).include?(11)
        'Инвалид'
      when benefits.map(&:benefit_document_type_id).include?(30)
        'Сирота'
      end
    else 
      benefit_type = 'Премущественное право'
    end
  end
  json.benefit_type benefit_type ? benefit_type : nil
  json.benefit_document_type benefit_document_type ? benefit_document_type : nil
  unless entrant.target_contracts.where(competitive_group_id: entrant.enrolled).empty?
    target_contract = entrant.target_contracts.find_by_competitive_group_id(entrant.enrolled)
    json.target_region = target_contract.target_organization.region_id
    json.target_organization_name = target_contract.target_organization.target_organization_name
  end
end
