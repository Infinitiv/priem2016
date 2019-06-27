json.campaigns @campaigns do |campaign|
  json.campaign campaign, :name, :id
  json.admission_volumes campaign.admission_volumes, :id, :direction_id
  json.competitive_groups campaign.competitive_groups, :id, :name, :direction_id
  json.institution_achievements campaign.institution_achievements, :id, :name, :max_value
end
