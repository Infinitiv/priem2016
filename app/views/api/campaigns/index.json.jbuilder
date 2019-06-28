json.campaigns @campaigns do |campaign|
  json.campaign campaign, :name, :id
  json.admission_volumes campaign.admission_volumes, :id, :direction_id
  json.competitive_groups campaign.competitive_groups, :id, :name, :direction_id
  json.institution_achievements campaign.institution_achievements, :id, :name, :max_value
  json.entrance_test_items campaign.entrance_test_items.uniq do |entrance_test_item|
    json.id entrance_test_item.id
    json.min_score entrance_test_item.min_score
    json.subject_name entrance_test_item.subject.subject_name
  end
end
