# TargetOrganization.create(id: 55, target_organization_name: 'ОБУЗ Стоматологическая поликлиника №1')
# Group.create(name: 'administrator')
# Group.create(name: 'supervisor')
# Group.create(name: 'clerk')
# User.create(login: 'МарковнинВР', password: 'VjFKhOG5', password_confirmation: 'VjFKhOG5')
User.create(login: 'ИвановСК', password: 'tlZPF5si', password_confirmation: 'tlZPF5si')
# User.find_by_login('МарковнинВР').groups << Group.find_by_name('administrator')
User.find_by_login('ИвановСК').groups << Group.find_by_name('supervisor')
