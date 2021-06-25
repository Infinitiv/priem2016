class AttachmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_attachment, only: [:show, :destroy]
  
  def show
    %x(ls "#{Rails.root.join('storage', @attachment.data_hash[0..2].split('').join('/'))}")
    path = Rails.root.join('storage', @attachment.data_hash[0..2].split('').join('/'), @attachment.data_hash)
    send_file path, :filename => @attachment.filename, :type => @attachment.mime_type
  end
    
  def destroy
    @attachment.destroy
    redirect_to :back
  end
  
  private
  
  def set_attachment
    @attachment = Attachment.find(params[:id])
  end
end
