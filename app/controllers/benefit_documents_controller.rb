class BenefitDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_benefit_document, only: [:update, :destroy, :convert_to_other_document]
  
  def convert_to_other_document
    entrant_application = @benefit_document.entrant_application
    other_document = entrant_application.other_documents.create(other_document_series: @benefit_document.benefit_document_series,
                         other_document_number: @benefit_document.benefit_document_number,
                         other_document_date: @benefit_document.benefit_document_date,
                         other_document_issuer: @benefit_document.benefit_document_organization)
    entrant_application.attachments.where(document_id: @benefit_document.id).update_all(document_type: 'other_document', document_id: other_document.id)
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @benefit_document.entrant_application.update_attributes(status_id: 2, status: new_value)
    @benefit_document.destroy
    if entrant_application.benefit_documents.empty?
      entrant_application.update_attributes(benefit: false)
    end
    redirect_to :back
  end
  
  def update
    @benefit_document.update(benefit_document_params)
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @benefit_document.entrant_application.update_attributes(status_id: 2, status: new_value)
    redirect_to :back
  end
  
  def destroy
    @benefit_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_benefit_document
    @benefit_document = BenefitDocument.find(params[:id])
  end
  
  def benefit_document_params
    params.require(:benefit_document).permit(:id, :benefit_type_id, :benefit_document_series, :benefit_document_number, :benefit_document_date, :benefit_document_type_id, :benefit_document_organization)
  end
end
