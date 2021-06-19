json.campaigns @campaigns do |campaign|
  json.name campaign.name
  json.id campaign.id
  json.campaignTypeId campaign.campaign_type_id
  json.yearStart campaign.year_start
  json.admissionVolumes campaign.admission_volumes do |admission_volume|
    json.id admission_volume.id
    json.directionId admission_volume.direction_id
  end
  json.competitiveGroups campaign.competitive_groups.order(name: :asc) do |competitive_group|
    json.id competitive_group.id
    json.name competitive_group.name
    json.directionId competitive_group.direction_id
    json.educationSourceId competitive_group.education_source_id
    json.applicationStartDate competitive_group.application_start_date
    json.applicationEndExamDate competitive_group.application_end_exam_date
    json.applicationEndEgeDate competitive_group.application_end_ege_date
    json.orderEndDate competitive_group.order_end_date
    json.number competitive_group.competitive_group_item.attributes.select{|k, v| k =~ /number/}.values.sum
  end
  json.institutionAchievements campaign.institution_achievements do |institution_achievement|
    json.id institution_achievement.id
    json.name institution_achievement.name
    json.maxValue institution_achievement.max_value
  end
  json.entranceTestItems campaign.entrance_test_items.uniq do |entrance_test_item|
    json.subjectId entrance_test_item.subject_id
    json.minScore entrance_test_item.min_score
    json.subjectName entrance_test_item.subject.subject_name
  end
end
