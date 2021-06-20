json.campaigns @campaigns do |campaign|
  json.name campaign.name
  json.id campaign.id
  json.campaign_type_id campaign.campaign_type_id
  json.year_start campaign.year_start
  json.admission_volumes campaign.admission_volumes do |admission_volume|
    json.id admission_volume.id
    json.direction_id admission_volume.direction_id
  end
  json.competitive_groups campaign.competitive_groups.order(name: :asc) do |competitive_group|
    json.id competitive_group.id
    json.name competitive_group.name
    json.direction_id competitive_group.direction_id
    json.education_source_id competitive_group.education_source_id
    json.application_start_date competitive_group.application_start_date
    json.application_end_exam_date competitive_group.application_end_exam_date
    json.application_end_ege_date competitive_group.application_end_ege_date
    json.order_end_date competitive_group.order_end_date
    json.number competitive_group.competitive_group_item.attributes.select{|k, v| k =~ /number/}.values.sum
  end
  json.institution_achievements campaign.institution_achievements do |institution_achievement|
    json.id institution_achievement.id
    json.name institution_achievement.name
    json.max_value institution_achievement.max_value
  end
  json.entrance_test_items campaign.entrance_test_items.uniq do |entrance_test_item|
    json.subject_id entrance_test_item.subject_id
    json.min_score entrance_test_item.min_score
    json.subject_name entrance_test_item.subject.subject_name
  end
end
