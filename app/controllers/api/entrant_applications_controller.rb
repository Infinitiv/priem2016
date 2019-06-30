class Api::EntrantApplicationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def show
    @entrant_application = EntrantApplication.includes(:identity_documents, :education_document, :marks, :achievements, :olympic_documents, :benefit_documents, :competitive_groups).find_by_data_hash(params[:id])
  end
  
  def create
    @entrant_application = ''
    send_data "{'ok'}"
  end
end
