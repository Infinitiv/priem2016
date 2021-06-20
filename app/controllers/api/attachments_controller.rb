class Api::AttachmentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :set_attachment, only: [:show]
  
  def show
    path = Rails.root.join('storage', @attachment.data_hash[0..2].split('').join('/'), @attachment.data_hash)
    %x(touch "#{path}")
    send_file path, :filename => 'file_name', :type => @attachment.mime_type, :disposition => "attachment"
  end
  
  def create
    unless attachment_params[:entrant_application_id].blank? || attachment_params[:files].nil?
      attachment_params[:files].each do |file|
        @attachment = Attachment.new
        @attachment.entrant_application_id = attachment_params[:entrant_application_id]
        @attachment.document_type = attachment_params[:document_type]
        @attachment.document_id = attachment_params[:document_id]
        @attachment.merged = false
        @attachment.template = false
        @attachment.uploaded_file(file)
        @attachment.save
      end
      if @attachment.document_type == 'entrant_application' && @attachment.template == false
        @attachment.entrant_application.update_attributes(status: 'заявление загружено')
      end
      if @attachment.document_type == 'consent_application' && @attachment.template == false
        @attachment.entrant_application.update_attributes(status: 'подано согласие на зачисление')
      end
      if @attachment.document_type == 'withdraw_application' && @attachment.template == false
        @attachment.entrant_application.update_attributes(status: 'подан отказ от зачисления')
      end
      if @attachment.document_type == 'recall_application' && @attachment.template == false
        @attachment.entrant_application.update_attributes(status: 'подано заявление об отзыве документов')
      end
      send_data({status: 'success', message: 'Файл успешно загружен', attachments: Attachment.where(entrant_application_id: attachment_params[:entrant_application_id])}.to_json)
    end
  end
  
  private
  
  def set_attachment
    @attachment = Attachment.find_by_data_hash(params[:id])
  end

  def attachment_params
    params.require(:attachment).permit(:entrant_application_id, :document_type, :document_id, files: [])
  end
end
