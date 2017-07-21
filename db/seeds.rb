# 2017
# меняем атрибуты документов 2016 года
EntrantApplication.all.each do |application|
  application.identity_documents.each do |document|
    document.update_attributes(entrant_application_id: application.id)
  end
end
# удаляем приемную кампанию
Campaign.find(2).destroy if Campaign.find_by_id(2)
# создаем приемную кампанию
Campaign.create(id: 2, name: "Специалитет", year_start: 2017, year_end: 2017, status_id: 1, campaign_type_id: 1, education_forms: [11], education_levels: [5], google_key_development: '1-h7uhz_idoE1MaAUBFLgl34Ok6aMv9l0JTmSlghHVzk', google_key_production: '1BkB6l93qpkK5VNJsPQ1fPxyWaGpCXBOkv1MXfdmbvQE')

# заполняем справочники
# добавляем заказчиков целевого приема
TargetOrganization.create(id: 10, target_organization_name: 'Брянская область (Белоберезовское городское поселение)').id
TargetOrganization.create(id: 11, target_organization_name: 'Брянская область (Бытошское городское поселение)').id
TargetOrganization.create(id: 12, target_organization_name: 'Брянская область (Ивотское городское поселение)').id
TargetOrganization.create(id: 13, target_organization_name: 'Брянская область (Карачевское городское поселение)').id
TargetOrganization.create(id: 14, target_organization_name: 'Брянская область (городской округ Клинцы)').id
TargetOrganization.create(id: 15, target_organization_name: 'Брянская область (Любохонское городское поселение)').id
TargetOrganization.create(id: 16, target_organization_name: 'Брянская область (Погарское городское поселение)').id
TargetOrganization.create(id: 17, target_organization_name: 'Брянская область (городской округ Сельцо)').id
TargetOrganization.create(id: 18, target_organization_name: 'Брянская область (Суражское городское поселение)').id
TargetOrganization.create(id: 19, target_organization_name: 'Брянская область (городской округ Фокино)').id
TargetOrganization.create(id: 20, target_organization_name: 'Владимирская область (городское поселение Вязники)').id
TargetOrganization.create(id: 21, target_organization_name: 'Владимирская область (городское поселение Гороховец)').id
TargetOrganization.create(id: 22, target_organization_name: 'Владимирская область (городское поселение Камешково)').id
TargetOrganization.create(id: 23, target_organization_name: 'Владимирская область (городское поселение Кольчугино)').id
TargetOrganization.create(id: 24, target_organization_name: 'Владимирская область (городское поселение Курлово)').id
TargetOrganization.create(id: 25, target_organization_name: 'Владимирская область (городское поселение Меленки)').id
TargetOrganization.create(id: 26, target_organization_name: 'Владимирская область (городское поселение Ставрово)').id
TargetOrganization.create(id: 27, target_organization_name: 'Ивановская область (городской округ Вичуга)').id
TargetOrganization.create(id: 28, target_organization_name: 'Ивановская область (Каменское городское поселение)').id
TargetOrganization.create(id: 29, target_organization_name: 'Ивановская область (Колобовское городское поселение)').id
TargetOrganization.create(id: 30, target_organization_name: 'Ивановская область (Наволокское городское поселение)').id
TargetOrganization.create(id: 31, target_organization_name: 'Ивановская область (Петровское городское поселение)').id
TargetOrganization.create(id: 32, target_organization_name: 'Ивановская область (Приволжское городское поселение)').id
TargetOrganization.create(id: 33, target_organization_name: 'Ивановская область (Савинское городское поселение)').id
TargetOrganization.create(id: 34, target_organization_name: 'Ивановская область (городской округ Тейково)').id
TargetOrganization.create(id: 35, target_organization_name: 'Ивановская область (Фурмановское городское поселение)').id
TargetOrganization.create(id: 36, target_organization_name: 'Ивановская область (Южское городское поселение)').id
TargetOrganization.create(id: 37, target_organization_name: 'Тульская область (городской округ Алексин)').id
TargetOrganization.create(id: 38, target_organization_name: 'Тульская область (городской округ Белев)').id
TargetOrganization.create(id: 39, target_organization_name: 'Тульская область (городской округ Ефремов)').id
TargetOrganization.create(id: 40, target_organization_name: 'Тульская область (городское поселение раб. пос. Первомайский)').id
TargetOrganization.create(id: 41, target_organization_name: 'Тульская область (городской округ Суворов)').id
TargetOrganization.create(id: 42, target_organization_name: 'ФСИН России').id

# добавляем вступительные испытания
EntranceTestItem.create(entrance_test_type_id: 1, min_score: 42, entrance_test_priority: 1, subject_id: 3)
EntranceTestItem.create(entrance_test_type_id: 1, min_score: 42, entrance_test_priority: 2, subject_id: 2)
EntranceTestItem.create(entrance_test_type_id: 1, min_score: 42, entrance_test_priority: 3, subject_id: 1)

# добавляем индивидуальные достижения
InstitutionAchievement.create(name: "Аттестат с золотой медалью", id_category: 15, max_value: 10, campaign_id: 2)
InstitutionAchievement.create(name: "Аттестат с серебряной медалью", id_category: 16, max_value: 10, campaign_id: 2)
InstitutionAchievement.create(name: "Аттестат с отличием", id_category: 9, max_value: 10, campaign_id: 2)
InstitutionAchievement.create(name: "Диплом с отличием", id_category: 17, max_value: 10, campaign_id: 2)
InstitutionAchievement.create(name: "Золотой знак отличия ГТО", id_category: 8, max_value: 2, campaign_id: 2)

# добавляем объемы приема
# Лечебное дело
campaign_id = Campaign.last.id
AdmissionVolume.create(id: 4, campaign_id: campaign_id, education_level_id: 5, direction_id: 17509, number_budget_o: 22, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 75, number_paid_oz: 0, number_paid_z: 0, number_target_o: 140, number_target_oz: 0, number_target_z: 0, number_quota_o: 18, number_quota_oz: 0, number_quota_z: 0)
# распределяем места по источникам финансирования
admission_volume = AdmissionVolume.last
DistributedAdmissionVolume.create(id: 4, admission_volume_id: admission_volume.id, level_budget_id: 1, number_budget_o: 22, number_budget_oz: 0, number_budget_z: 0, number_target_o: 140, number_target_oz: 0, number_target_z: 0, number_quota_o: 18, number_quota_oz: 0, number_quota_z: 0)
# Педиатрия
AdmissionVolume.create(id: 5, campaign_id: campaign_id, education_level_id: 5, direction_id: 17353, number_budget_o: 46, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 90, number_paid_oz: 0, number_paid_z: 0, number_target_o: 62, number_target_oz: 0, number_target_z: 0, number_quota_o: 12, number_quota_oz: 0, number_quota_z: 0)
# распределяем места по источникам финансирования
admission_volume = AdmissionVolume.last
DistributedAdmissionVolume.create(id: 5, admission_volume_id: admission_volume.id, level_budget_id: 1, number_budget_o: 46, number_budget_oz: 0, number_budget_z: 0, number_target_o: 62, number_target_oz: 0, number_target_z: 0, number_quota_o: 12, number_quota_oz: 0, number_quota_z: 0)
# Стоматология
AdmissionVolume.create(id: 6, campaign_id: campaign_id, education_level_id: 5, direction_id: 17247, number_budget_o: 4, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 25, number_paid_oz: 0, number_paid_z: 0, number_target_o: 9, number_target_oz: 0, number_target_z: 0, number_quota_o: 2, number_quota_oz: 0, number_quota_z: 0)
# распределяем места по источникам финансирования
admission_volume = AdmissionVolume.last
DistributedAdmissionVolume.create(id: 6, admission_volume_id: admission_volume.id, level_budget_id: 1, number_budget_o: 4, number_budget_oz: 0, number_budget_z: 0, number_target_o: 9, number_target_oz: 0, number_target_z: 0, number_quota_o: 2, number_quota_oz: 0, number_quota_z: 0)

# добавляем конкурсные группы
# Лечебное дело
CompetitiveGroup.create(campaign_id: campaign_id, name: "Лечебное дело. Бюджет.", education_level_id: 5, education_source_id: 14, education_form_id: 11, direction_id: 17509)
competitive_group = CompetitiveGroup.last
# добавляем элементы конкурсных групп
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 22, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.01")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Лечебное дело. Внебюджет.", education_level_id: 5, education_source_id: 15, education_form_id: 11, direction_id: 17509)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 75, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.01")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Лечебное дело. Квота особого права.", education_level_id: 5, education_source_id: 20, education_form_id: 11, direction_id: 17509)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 18, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.01")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Лечебное дело. Целевые места.", education_level_id: 5, education_source_id: 16, education_form_id: 11, direction_id: 17509)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 140, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.01")
# создаем целевые места
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Белоберезовское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Бытошское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Ивотское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Карачевское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (городской округ Клинцы)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Любохонское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Погарское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (городской округ Сельцо)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (Суражское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Брянская область (городской округ Фокино)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Вязники)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Гороховец)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Камешково)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Меленки)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (городской округ Вичуга)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Колобовское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Приволжское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Савинское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Фурмановское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Тульская область (городской округ Алексин)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Тульская область (городской округ Белев)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Тульская область (городской округ Ефремов)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Тульская область (городское поселение раб. пос. Первомайский)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Тульская область (городской округ Суворов)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('ФСИН России').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Брянской области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Владимирской области').id, competitive_group_id: competitive_group.id, number_target_o: 26, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Вологодской области').id, competitive_group_id: competitive_group.id, number_target_o: 5, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Ивановской области').id, competitive_group_id: competitive_group.id, number_target_o: 48, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Костромской области').id, competitive_group_id: competitive_group.id, number_target_o: 25, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Липецкой области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Тульской области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Федеральное медико-биологическое агентство').id, competitive_group_id: competitive_group.id, number_target_o: 5, number_target_oz: 0, number_target_z: 0)

# Педиатрия
CompetitiveGroup.create(campaign_id: campaign_id, name: "Педиатрия. Бюджет.", education_level_id: 5, education_source_id: 14, education_form_id: 11, direction_id: 17353)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 46, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.02")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Педиатрия. Внебюджет.", education_level_id: 5, education_source_id: 15, education_form_id: 11, direction_id: 17353)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 90, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.02")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Педиатрия. Квота особого права.", education_level_id: 5, education_source_id: 20, education_form_id: 11, direction_id: 17353)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 12, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.02")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Педиатрия. Целевые места.", education_level_id: 5, education_source_id: 16, education_form_id: 11, direction_id: 17353)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 62, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.02")
# создаем целевые места
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Кольчугино)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Курлово)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Владимирская область (городское поселение Ставрово)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Каменское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Наволокское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Петровское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (городской округ Тейково)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Ивановская область (Южское городское поселение)').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Брянской области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Владимирской области').id, competitive_group_id: competitive_group.id, number_target_o: 12, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Вологодской области').id, competitive_group_id: competitive_group.id, number_target_o: 4, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Ивановской области').id, competitive_group_id: competitive_group.id, number_target_o: 17, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Костромской области').id, competitive_group_id: competitive_group.id, number_target_o: 16, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Тульской области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Федеральное медико-биологическое агентство').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)

# Стоматология
CompetitiveGroup.create(campaign_id: campaign_id, name: "Стоматология. Бюджет.", education_level_id: 5, education_source_id: 14, education_form_id: 11, direction_id: 17247)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 4, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.03")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Стоматология. Внебюджет.", education_level_id: 5, education_source_id: 15, education_form_id: 11, direction_id: 17247)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 25, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.03")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Стоматология. Квота особого права.", education_level_id: 5, education_source_id: 20, education_form_id: 11, direction_id: 17247)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 0, number_target_oz: 0, number_target_z: 0, number_quota_o: 2, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.03")

CompetitiveGroup.create(campaign_id: campaign_id, name: "Стоматология. Целевые места.", education_level_id: 5, education_source_id: 16, education_form_id: 11, direction_id: 17247)
# добавляем элементы конкурсных групп
competitive_group = CompetitiveGroup.last
CompetitiveGroupItem.create(competitive_group_id: competitive_group.id, number_budget_o: 0, number_budget_oz: 0, number_budget_z: 0, number_paid_o: 0, number_paid_oz: 0, number_paid_z: 0, number_target_o: 9, number_target_oz: 0, number_target_z: 0, number_quota_o: 0, number_quota_oz: 0, number_quota_z: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.05.03")
# создаем целевые места
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Владимирской области').id, competitive_group_id: competitive_group.id, number_target_o: 2, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Ивановской области').id, competitive_group_id: competitive_group.id, number_target_o: 5, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Костромской области').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)
TargetNumber.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Федеральное медико-биологическое агентство').id, competitive_group_id: competitive_group.id, number_target_o: 1, number_target_oz: 0, number_target_z: 0)

# прикрепляем вступительные испытания к конкурсным группам
CompetitiveGroup.where(campaign_id: campaign_id).each{|cg| cg.entrance_test_items << EntranceTestItem.where(min_score: 42)}



#Campaign.create(name: "Кадры высшей квалификации", year_start: 2017, year_end: 2017, status_id: 1, campaign_type_id: 4, education_forms: [11], education_levels: [18])