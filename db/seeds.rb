# 2017
# заполняем справочники
# добавляем заказчиков целевого приема
TargetOrganization.create(id: 43, target_organization_name: 'Министерство здравоохранения Чеченской республики')

# добавляем образовательные программы
EduProgram.create(name: 'Акушерство и гинекология', code: '31.08.01')
EduProgram.create(name: 'Аллергология и иммунология', code: '31.08.26')
EduProgram.create(name: 'Анестезиология-реаниматология', code: '31.08.02')
EduProgram.create(name: 'Гастроэнтерология', code: '31.08.28')
EduProgram.create(name: 'Дерматовенерология', code: '31.08.32')
EduProgram.create(name: 'Детская кардиология ', code: '31.08.13')
EduProgram.create(name: 'Детская урология - андрология', code: '31.08.15')
EduProgram.create(name: 'Детская хирургия', code: '31.08.16')
EduProgram.create(name: 'Детская эндокринология', code: '31.08.17')
EduProgram.create(name: 'Инфекционные болезни', code: '31.08.35')
EduProgram.create(name: 'Кардиология', code: '31.08.36')
EduProgram.create(name: 'Лечебная физкультура и спортивная медицина', code: '31.08.39')
EduProgram.create(name: 'Неврология', code: '31.08.42')
EduProgram.create(name: 'Нейрохирургия', code: '31.08.56')
EduProgram.create(name: 'Неонатология ', code: '31.08.18')
EduProgram.create(name: 'Нефрология', code: '31.08.43')
EduProgram.create(name: 'Общая врачебная практика (семейная медицина)', code: '31.08.54')
EduProgram.create(name: 'Онкология', code: '31.08.57')
EduProgram.create(name: 'Оториноларингология', code: '31.08.58')
EduProgram.create(name: 'Офтальмология', code: '31.08.59')
EduProgram.create(name: 'Патологическая анатомия ', code: '31.08.07')
EduProgram.create(name: 'Педиатрия', code: '31.08.19')
EduProgram.create(name: 'Психиатрия', code: '31.08.20')
EduProgram.create(name: 'Психиатрия-наркология', code: '31.08.21')
EduProgram.create(name: 'Пульмонология', code: '31.08.45')
EduProgram.create(name: 'Рентгенология', code: '31.08.09')
EduProgram.create(name: 'Скорая медицинская помощь', code: '31.08.48')
EduProgram.create(name: 'Стоматология ортопедическая', code: '31.08.75')
EduProgram.create(name: 'Стоматология хирургическая', code: '31.08.74')
EduProgram.create(name: 'Судебно-медицинская экспертиза', code: '31.08.10')
EduProgram.create(name: 'Терапия', code: '31.08.49')
EduProgram.create(name: 'Травматология и ортопедия', code: '31.08.66')
EduProgram.create(name: 'Урология', code: '31.08.68')
EduProgram.create(name: 'Фтизиатрия', code: '31.08.51')
EduProgram.create(name: 'Хирургия', code: '31.08.67')
EduProgram.create(name: 'Эндокринология', code: '31.08.53')

# добавляем вступительные испытания
subject = Subject.create(subject_name: "Здравоохранение")
subject.entrance_test_items.create(entrance_test_type_id: 1, min_score: 70, entrance_test_priority: 1)

# добавялем приемную кампанию
campaign = Campaign.create(name: "Кадры высшей квалификации", year_start: 2017, year_end: 2017, status_id: 1, campaign_type_id: 4, education_forms: [11], education_levels: [18])

# добавляем индивидуальные достижения
campaign.institution_achievements.create(name: "Стипендиаты Президента Российской Федерации, Правительства Российской Федерации", id_category: 13, max_value: 100)
campaign.institution_achievements.create(name: "Стипендиаты именных стипендий", id_category: 13, max_value: 50)
campaign.institution_achievements.create(name: "Документ установленного образца с отличием", id_category: 13, max_value: 100)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников менее 3 лет", id_category: 13, max_value: 50)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников 3 и более лет", id_category: 13, max_value: 80)
campaign.institution_achievements.create(name: "Общий стаж работы в должностях медицинских и (или) фармацевтических работников в сельской местности", id_category: 13, max_value: 90)
campaign.institution_achievements.create(name: "ИвГМА: наличие рекомендации образовательной организации
высшего образования", id_category: 13, max_value: 10)
campaign.institution_achievements.create(name: "ИвГМА: наличие рекомендации медицинской организации", id_category: 13, max_value: 5)
campaign.institution_achievements.create(name: "ИвГМА: статья в зарубежных журналах", id_category: 13, max_value: 10)
campaign.institution_achievements.create(name: "ИвГМА: статья в рецензируемых журналах РФ", id_category: 13, max_value: 5)
campaign.institution_achievements.create(name: "ИвГМА: статья в нерецензируемых журналах", id_category: 13, max_value: 3)
campaign.institution_achievements.create(name: "ИвГМА: публикация в сборниках региональных конференций", id_category: 13, max_value: 1)
campaign.institution_achievements.create(name: "ИвГМА: наличие изобретения", id_category: 13, max_value: 10)

# добавляем объемы приема
# Акушерство и гинекология
admission_volume = campaign.admission_volumes.create(education_level_id: 18, direction_id: 17678, number_budget_o: 5, number_paid_o: 5, number_target_o: 4)
# распределяем места по источникам финансирования
admission_volume.distributed_admission_volumes.create(level_budget_id: 1, number_budget_o: 5, number_target_o: 4)

# добавляем конкурсные группы
# Акушерство и гинекология
competitive_group = campaign.competitive_groups.create(name: "Акушерство и гинекология. Бюджет.", education_level_id: 18, education_source_id: 14, education_form_id: 11, direction_id: 17678)
# добавляем элементы конкурсных групп
competitive_group.competitive_group_items.create(number_budget_o: 5, number_paid_o: 0, number_target_o: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.08.01")

competitive_group = campaign.competitive_groups.create(name: "Акушерство и гинекология. Внебюджет.", education_level_id: 18, education_source_id: 15, education_form_id: 11, direction_id: 17678)
# добавляем элементы конкурсных групп
competitive_group.competitive_group_items.create(number_budget_o: 0, number_paid_o: 5, number_target_o: 0)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.08.01")

competitive_group = campaign.competitive_groups.create(name: "Акушерство и гинекология. Целевые места.", education_level_id: 18, education_source_id: 16, education_form_id: 11, direction_id: 17678)
# добавляем элементы конкурсных групп
competitive_group.competitive_group_items.create(number_budget_o: 0, number_paid_o: 0, number_target_o: 4)
# прикрепляем образовательные программы
competitive_group.edu_programs << EduProgram.find_by_code("31.08.01")
# создаем целевые места
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Владимирской области').id, number_target_o: 1)
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Ивановской области').id, number_target_o: 2)
competitive_group.target_numbers.create(target_organization_id: TargetOrganization.find_by_target_organization_name('Департамент здравоохранения Костромской области').id, number_target_o: 1)

# прикрепляем вступительные испытания к конкурсным группам
campaign.competitive_groups.each{|cg| cg.entrance_test_items << EntranceTestItem.where(min_score: 70)}
