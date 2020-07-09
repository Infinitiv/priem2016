class EducationDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_education_document, only: [:update, :destroy]
  
  def update
    @education_document.update(education_document_params)
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @education_document.entrant_application.update_attributes(status_id: 2, status: new_value)
    redirect_to :back
  end
  
  def destroy
    @education_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_education_document
    @education_document = EducationDocument.find(params[:id])
  end
  
  def education_document_params
    params.require(:education_document).permit(:id, :education_document_number, :education_document_date, :education_document_issuer)
  end
end
