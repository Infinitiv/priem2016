class IdentityDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_edu_program, only: [:destroy]
  
  def destroy
    @identity_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_edu_program
    @identity_document = IdentityDocument.find(params[:id])
  end
end
