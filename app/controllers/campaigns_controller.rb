class CampaignsController < ApplicationController
  before_action :set_select, only: [:new, :edit, :update, :create]
  before_action :campaign_params, only: [:create]
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]
  
  def index
    @campaigns = Campaign.order(:name)
  end
  
  def new
    @campaign = Campaign.new
  end
  
  def create
    @campaign = Campaign.new(campaign_params)
    if @campaign.save
      redirect_to @campaign, notice: 'Кампания успешно добавлена'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @campaign.update(campaign_params)
      redirect_to @campaign
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @campaign.destroy
    redirect_to campaigns_path
  end
  
  private
  def set_select
    @statuses = {'Набор не начался' => 0,
                 'Идет набор' => 1,
                 'Завершена' => 2
                }
    @campaign_types = {'Прием на обучение на бакалавриат/специалитет' => 1,
                       'Прием на подготовку кадров высшей квалификации' => 4,
                       'Прием иностранцев по направлениям Минобрнауки' => 5
                      }
    @education_levels = {'Специалитет' => 5,
                        'Кадры высшей квалификации' => 18
                       }
    @education_forms = {'Заочная форма' => 10,
                        'Очная форма' => 11}
  end
  
  def campaign_params
    params.require(:campaign).permit(:name, :year_start, :year_end, :status_id, :campaign_type_id, education_forms: [], education_levels: [])
  end
  
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end