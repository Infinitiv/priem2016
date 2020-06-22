class Events < ActionMailer::Base
  helper ApplicationHelper
  default from: "no-reply@isma.ivanovo.ru"
  
  def generate_templates(entrant_application)
    @entrant_application = entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
  
  def welcome_mail(entrant_application)
    @entrant_application = entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
  
  def add_comment(entrant_application)
    @entrant_application = entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
end
