class Api::AttachmentsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :set_attachment, only: [:show]
  
  def show
    path = @attachment.data_hash[0..2].split('').join('/')
    send_file Rails.root.join('storage', path, @attachment.data_hash), :filename => 'file_name', :type => @attachment.mime_type, :disposition => "attachment"
  end
  
  def create
    message = ''
    if attachment_params[:entrant_application_id].blank? || attachment_params[:files].empty?
      message = {status: 'error'}
    else
      attachment_params[:files].each do |file|
        @attachment = Attachment.new
        @attachment.entrant_application_id = attachment_params[:entrant_application_id]
        @attachment.document_type = attachment_params[:document_type]
        @attachment.document_id = attachment_params[:document_id]
        @attachment.merged = false
        @attachment.template = false
        @attachment.uploaded_file(file)
        message = {status: 'success'} if @attachment.save
      end
    end
    send_data(message.to_json)
  end
  
  private
  
  def set_attachment
    @attachment = Attachment.find_by_data_hash(params[:id])
  end

  def attachment_params
    params.require(:attachment).permit(:entrant_application_id, :document_type, :document_id, files: [])
  end
end
