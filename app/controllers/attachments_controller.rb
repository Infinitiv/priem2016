class AttachmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_attachment, only: [:show, :destroy]
  
  def show
  end
    
  def destroy
    if @attachment.destroy
      path = @attachment.data_hash[0..2].split('').join('/')
      File.delete(Rails.root.join('storage', path, file_name)) if file_name
    end
    redirect_to :back
  end
  
  private
  
  def set_attachment
    @attachment = Attachment.find_by_data_hash(params[:id])
  end
end
