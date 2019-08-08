json.array! @competitive_groups do |competitive_group|
  json.id competitive_group.id
  json.name competitive_group.name
  json.education_source_id competitive_group.education_source_id
  json.direction_id competitive_group.direction_id
  json.last_admission_date competitive_group.last_admission_date
  json.number_budget_o competitive_group.competitive_group_item.number_budget_o
  json.number_paid_o competitive_group.competitive_group_item.number_paid_o
  json.number_target_o competitive_group.competitive_group_item.number_target_o
  json.number_quota_o competitive_group.competitive_group_item.number_quota_o
end
