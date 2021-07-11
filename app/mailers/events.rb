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
  
  def check_pin(entrant_application)
    @entrant_application = entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
  
  def add_comment(entrant_application)
    @entrant_application = entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
  
  def mailing_to_exam(row)
    @row = row
    mail(to: @row[:email], subject: 'Приемная комиссия ИвГМА сообщает')
  end
  
  def ticket_question(ticket)
    @ticket = ticket
    mail(to: 'it@isma.ivanovo.ru', subject: 'Новое сообщение о проблеме')
  end
  
  def ticket_answer(ticket)
    @ticket = ticket
    @entrant_application = ticket.entrant_application
    mail(to: @entrant_application.email, subject: 'Приемная комиссия ИвГМА сообщает')
  end
end
