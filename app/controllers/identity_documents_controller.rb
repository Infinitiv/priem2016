class IdentityDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_identity_document, only: [:update, :destroy]
  
  def update
    @identity_document.update(identity_document_params)
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @identity_document.entrant_application.update_attributes(status_id: 2, status: new_value)
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
