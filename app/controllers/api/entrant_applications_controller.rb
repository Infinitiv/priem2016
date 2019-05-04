class Api::EntrantApplicationsController < ApplicationController
  def show
    @entrant_application = EntrantApplication.includes(:identity_documents, :education_document, :marks, :achievements, :olympic_documents, :benefit_documents, :competitive_groups).find_by_data_hash(params[:id])
  end
end
