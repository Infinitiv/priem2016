class MarksController < ApplicationController
  load_and_authorize_resource
  before_action :set_mark, only: [:update, :destroy]
  
  def create
    @mark = Mark.create(mark_params)
    @mark.entrant_application.update_attributes(status_id: 2, status: 'внесены изменения')
    redirect_to :back
  end
  
  def update
    @mark.update(mark_params)
    @mark.entrant_application.update_attributes(status_id: 2, status: 'внесены изменения')
    redirect_to :back
  end
  
  def destroy
    @mark.destroy
    redirect_to :back
  end
  
  private
  
  def set_mark
    @mark = Mark.find(params[:id])
  end
  
  def mark_params
    params.require(:mark).permit(:id, :entrant_application_id, :subject_id, :value, :form)
  end
end
