class OlympicDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_olympic_document, only: [:update, :destroy, :convert_to_other_document]
  
  def convert_to_other_document
    entrant_application = @olympic_document.entrant_application
    other_document = entrant_application.other_documents.create(other_document_series: @olympic_document.olympic_document_series,
                         other_document_number: @olympic_document.olympic_document_number,
                         other_document_date: @olympic_document.olympic_document_date)
    entrant_application.attachments.where(document_id: @olympic_document.id).update_all(document_type: 'other_document', document_id: other_document.id)
    @olympic_document.destroy
    if entrant_application.olympic_documents.empty?
      entrant_application.update_attributes(olympionic: false)
    end
    redirect_to :back
  end
  
  def update
    @olympic_document.update(olympic_document_params)
    @olympic_document.entrant_application.update_attributes(status_id: 2, status: 'внесены изменения')
    redirect_to :back
  end
  
  def destroy
    @olympic_document.destroy
    redirect_to :back
  end
  
  private
  
  def set_olympic_document
    @olympic_document = OlympicDocument.find(params[:id])
  end
  
  def olympic_document_params
    params.require(:olympic_document).permit(:id, :olympic_profile_id, :diploma_type_id, :olympic_id, :olympic_profile_id, :class_number, :olympic_document_series, :olympic_document_number, :olympic_document_date, :olympic_subject_id, :ege_subject_id, :olympic_document_type_id)
  end
end
