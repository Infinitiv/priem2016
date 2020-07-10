class MarksController < ApplicationController
  load_and_authorize_resource
  before_action :set_mark, only: [:update, :destroy]
  
  def create
    @mark = Mark.create(mark_params)
    value_name = 'status_update'
    old_value = @mark.entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @mark.entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @mark.entrant_application.update_attributes(status_id: 2, status: new_value)
    redirect_to :back
  end
  
  def update
    @mark.update(mark_params)
    value_name = 'status_update'
    old_value = @mark.entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @mark.entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @mark.entrant_application.update_attributes(status_id: 2, status: new_value)
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
    params.require(:mark).permit(:id, :entrant_application_id, :subject_id, :value, :form, :year, :organization_uid)
  end
end
