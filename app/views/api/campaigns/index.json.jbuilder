json.campaigns @campaigns do |campaign|
  json.campaign campaign, :name, :id
  json.admission_volumes campaign.admission_volumes do |admission_volume|
    json.admission_volume admission_volume, :id, :direction_id
  end
  json.competitive_groups campaign.competitive_groups, :id, :name, :direction_id
end
