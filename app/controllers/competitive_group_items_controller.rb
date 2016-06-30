class CompetitiveGroupItemsController < ApplicationController
  before_action :set_competitive_group_item, only: [:show, :edit, :update, :destroy]
  before_action :competitive_group_item_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :create, :edit, :update]
  def index
    @competitive_group_items = CompetitiveGroupItem.order(:created_at)
  end
  
  def show
    
  end
  
  def new
    @competitive_group_item = CompetitiveGroupItem.new
    @competitive_group_item.competitive_group_id = params[:competitive_group_id]
  end
  
  def create
    @competitive_group_item = CompetitiveGroupItem.new(competitive_group_item_params)
    if @competitive_group_item.save
      redirect_to @competitive_group_item, notice: 'Competitive Group Item successfully created'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @competitive_group_item.update(competitive_group_item_params)
      redirect_to @competitive_group_item, notice: 'Competitive Group Item successfully updated'
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @competitive_group_item.destroy
    redirect_to competitive_group_items_path
  end
  
  private
  
  def set_competitive_group_item
    @competitive_group_item = CompetitiveGroupItem.find(params[:id])
  end
  
  def competitive_group_item_params
    params.require(:competitive_group_item).permit(:competitive_group_id, :number_budget_o, :number_budget_oz, :number_budget_z, :number_paid_o, :number_paid_oz, :number_paid_z, :number_target_o, :number_target_oz, :number_target_z, :number_quota_o, :number_quota_oz, :number_quota_z)
  end
  
  def set_selects
    @competitive_groups = CompetitiveGroup.order(:name)
  end
end