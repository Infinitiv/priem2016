class IdentityDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_identity_document, only: [:update, :destroy]
  
  def update
    @identity_document.update(identity_document_params)
    redirect_to :back
  end
  
  def destroy
    @identity_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_identity_document
    @identity_document = IdentityDocument.find(params[:id])
  end
  
  def identity_document_params
    params.require(:identity_document).permit(:id, :identity_document_series, :identity_document_number, :identity_document_date, :alt_entrant_last_name, :alt_entrant_first_name, :alt_entrant_middle_name, :identity_document_issuer)
  end
end
