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
  
  def mailing_to_exam(row)
    @row = row
#     mail(to: @row[:email], subject: 'Приемная комиссия ИвГМА сообщает')
    mail(to: 'markovnin@isma.ivanovo.ru', subject: 'Приемная комиссия ИвГМА сообщает')
  end
end
