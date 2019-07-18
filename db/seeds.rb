EntrantApplication.where.not(target_organization_id: nil).each do |entrant_application|
  puts entrant_application.application_number
  target_competitive_group = entrant_application.competitive_groups.where(education_source_id: 16).first
  entrant_application.target_contracts.create(target_organization_id: entrant_application.target_organization_id, competitive_group_id: target_competitive_group.id) if target_competitive_group
end
