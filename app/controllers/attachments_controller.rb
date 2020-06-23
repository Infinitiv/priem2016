class AttachmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_attachment, only: [:show, :destroy]
  
  def show
    path = @attachment.data_hash[0..2].split('').join('/')
    send_file Rails.root.join('storage', path, @attachment.data_hash), :filename => @attachment.filename, :type => @attachment.mime_type
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
