class AttachmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_attachment, only: [:show, :destroy]
  
  def show
    %x(ls "#{Rails.root.join('storage', @attachment.data_hash[0..2].split('').join('/'))}")
    path = Rails.root.join('storage', @attachment.data_hash[0..2].split('').join('/'), @attachment.data_hash)
    send_file path, filename: @attachment.filename, type: @attachment.mime_type, disposition: :inline
  end
    
  def destroy
    if @attachment.document_type == 'contract' && !@attachment.template
      entrant_application_id = @attachment.entrant_application_id
      document_id = @attachment.document_id
      Attachment.where(document_type: 'contract', document_id: document_id, entrant_application_id: entrant_application_id, template: true).destroy_all
    end
    @attachment.destroy
    redirect_to :back
  end
  
  private
  
  def set_attachment
    @attachment = Attachment.find(params[:id])
  end
end
