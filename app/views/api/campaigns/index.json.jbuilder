json.campaigns @campaigns do |campaign|
  json.name campaign.name
  json.id campaign.id
  json.campaign_type_id campaign.campaign_type_id
  json.year_start campaign.year_start
  json.admission_volumes campaign.admission_volumes, :id, :direction_id
  json.competitive_groups campaign.competitive_groups.order(name: :asc) do |competitive_group|
    json.id competitive_group.id
    json.name competitive_group.name
    json.direction_id competitive_group.direction_id
    json.application_start_date competitive_group.application_start_date
    json.application_end_exam_date competitive_group.application_end_exam_date
    json.application_end_ege_date competitive_group.application_end_ege_date
    json.order_end_date competitive_group.order_end_date
    json.target_organizations competitive_group.target_organizations, :id, :target_organization_name
  end
  json.institution_achievements campaign.institution_achievements, :id, :name, :max_value
  json.entrance_test_items campaign.entrance_test_items.uniq do |entrance_test_item|
    json.subject_id entrance_test_item.subject_id
    json.min_score entrance_test_item.min_score
    json.subject_name entrance_test_item.subject.subject_name
  end
end
