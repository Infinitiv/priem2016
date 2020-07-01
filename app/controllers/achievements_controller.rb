class AchievementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_achievement, only: [:update, :destroy]
  
  def create
    @achievement = Achievement.create(achievement_params)
    @achievement.entrant_application.update_attributes(status_id: 2, status: 'внесены изменения')
    redirect_to :back
  end
  
  def update
    @achievement.update(achievement_params)
    redirect_to :back
  end
  
  def destroy
    @achievement.entrant_application.update_attributes(status_id: 2, status: 'внесены изменения')
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
