class AchievementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_achievement, only: [:update, :destroy]
  
  def create
    @achievement = Achievement.create(achievement_params)
    value_name = 'status_update'
    old_value = @achievement.entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @achievement.entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @achievement.entrant_application.update_attributes(status_id: 2, status: new_value)
    redirect_to :back
  end
  
  def update
    @achievement.update(achievement_params)
    redirect_to :back
  end
  
  def destroy
    value_name = 'status_update'
    old_value = @achievement.entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @achievement.entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @achievement.entrant_application.update_attributes(status_id: 2, status: new_value)
    @achievement.destroy
    redirect_to :back
  end
  
  private
  
  def set_achievement
    @achievement = Achievement.find(params[:id])
  end
  
  def achievement_params
    params.require(:achievement).permit(:id, :entrant_application_id, :institution_achievement_id, :value)
  end
end
