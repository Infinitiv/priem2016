class CompetitiveGroupsController < ApplicationController
  before_action :set_competitive_group, only: [:show, :edit, :update, :destroy, :add_education_program, :remove_education_program, :add_entrance_test_item, :remove_entrance_test_item]
  before_action :competitive_group_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit, :update, :create]
  before_action :set_edu_program, only: [:add_education_program, :remove_education_program]
  before_action :set_entrance_test_item, only: [:add_entrance_test_item, :remove_entrance_test_item]
  
  def index
    @campaigns = Campaign.order(:name).where(year_start: Time.now.year)
  end
  
  def show
    @edu_programs = EduProgram.all - @competitive_group.edu_programs
    @entrance_test_items = EntranceTestItem.all - @competitive_group.entrance_test_items
  end
  
  def new
    @competitive_group = CompetitiveGroup.new
  end
  
  def create
    @competitive_group = CompetitiveGroup.new(competitive_group_params)
    if @competitive_group.save
      redirect_to @competitive_group, notice: 'Competitive Group successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @competitive_group.update(competitive_group_params)
      redirect_to @competitive_group
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @competitive_group.destroy
    redirect_to competitive_groups_path
  end
  
  def add_education_program
    @competitive_group.edu_programs << @edu_program
    redirect_to :back
  end
  
  def remove_education_program
    @competitive_group.edu_programs.delete @edu_program
    redirect_to :back
  end
  
  def add_entrance_test_item
    @competitive_group.entrance_test_items << @entrance_test_item
    redirect_to :back
  end
  
  def remove_entrance_test_item
    @competitive_group.entrance_test_items.delete @entrance_test_item
    redirect_to :back
  end
  
  private
  
  def set_competitive_group
    @competitive_group = CompetitiveGroup.find(params[:id])
  end
  
  
  def set_edu_program
    @edu_program = EduProgram.find(params[:edu_program_id])
  end
  
  def set_entrance_test_item
    @entrance_test_item = EntranceTestItem.find(params[:entrance_test_item_id])
  end
  
  def competitive_group_params
    params.require(:competitive_group).permit(:campaign_id, :name, :education_level_id, :education_source_id, :education_form_id, :direction_id, :is_for_krym, :is_additional)
  end
  
  def set_selects
    @education_levels = {'Специалитет' => 5,
                        'Кадры высшей квалификации' => 18
                       }
    @education_forms = {'Заочная форма' => 10,
                        'Очная форма' => 11}
    @directions = {'Лечебное дело' => 17509,
                   'Педиатрия' => 17353,
                  'Стоматология' => 17247}
    @education_sources = {'Бюджетные места' => 14,
                          'Квота приема лиц, имеющих особое право' => 20,
                          'С оплатой обучения' => 15,
                          'Целевой прием' => 16}
    @campaigns = Campaign.order(:year_start)
  end
end