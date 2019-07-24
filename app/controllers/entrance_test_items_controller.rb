class EntranceTestItemsController < ApplicationController
  load_and_authorize_resource
  before_action :set_entrance_test_item, only: [:show, :edit, :update, :destroy]
  before_action :entrance_test_item_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :create, :edit, :update]
  def index
    @entrance_test_items = EntranceTestItem.order(:created_at)
  end
  
  def show
    
  end
  
  def new
    @entrance_test_item = EntranceTestItem.new
  end
  
  def create
    @entrance_test_item = EntranceTestItem.new(entrance_test_item_params)
    if @entrance_test_item.save
      redirect_to competitive_groups_url, notice: 'Entrance Test Item successfully created'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @entrance_test_item.update(entrance_test_item_params)
      redirect_to @entrance_test_item, notice: 'Entrance Test Item successfully updated'
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @entrance_test_item.destroy
    redirect_to entrance_test_items_path
  end
  
  private
  
  def set_entrance_test_item
    @entrance_test_item = EntranceTestItem.find(params[:id])
  end
  
  def entrance_test_item_params
    params.require(:entrance_test_item).permit(:entrance_test_type_id, :min_score, :entrance_test_priority, :subject_id)
  end
  
  def set_selects
    @subjects = Subject.order(:subject_name)
    @entrance_test_types = {'Вступительные испытания': 1,
                            'Вступительные испытания творческой и (или) профессиональной направленности': 2,
                            'Вступительные испытания профильной направленности': 3}
  end
end
