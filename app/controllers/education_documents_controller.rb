class EducationDocumentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_education_document, only: [:update, :destroy]
  
  def update
    @education_document.update(education_document_params)
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
