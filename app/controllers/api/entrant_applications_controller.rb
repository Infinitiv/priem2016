class Api::EntrantApplicationsController < ApplicationController
  def show
    @entrant_application = EntrantApplication.find_by_application_number(params[:id])
  end
end
