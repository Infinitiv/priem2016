class InstitutionAchievementsController < ApplicationController
  before_action :set_institution_achievement, only: [:show, :edit, :update, :destroy]
  before_action :institution_achievement_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit]
  
  def index
    @institution_achievements = InstitutionAchievement.order(:created_at)
  end
  
  def show
  end
  
  def new
    @institution_achievement = InstitutionAchievement.new
  end
  
  def create
    @institution_achievement = InstitutionAchievement.new(institution_achievement_params)
    if @institution_achievement.save
      redirect_to @institution_achievement, notice: 'Institution Achievement successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @institution_achievement.update(institution_achievement_params)
      redirect_to @institution_achievement
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @institution_achievement.destroy
    redirect_to institution_achievements_path
  end
  
  private
  
  def set_institution_achievement
    @institution_achievement = InstitutionAchievement.find(params[:id])
  end
  
  def institution_achievement_params
    params.require(:institution_achievement).permit(:name, :id_category, :max_value, :campaign_id)
  end
  
  def set_selects
    @campaigns = Campaign.order(:year_start)
    @categories = {'Золотой знак отличия ГТО' => 8,
                   'Аттестат о среднем общем образовании с отличием' => 9,
                  'Аттестат о среднем (полном) общем образовании, золотая медаль' => 15,
                   'Аттестат о среднем (полном) общем образовании, серебряная медаль' => 16,
                   'Диплом о среднем профессиональном образовании с отличием' => 17}
  end
end
