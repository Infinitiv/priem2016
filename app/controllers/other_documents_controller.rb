class OtherDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_other_document, only: [:destroy]
  
  def destroy
    @other_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_other_document
    @other_document = OtherDocument.find(params[:id])
  end
end
