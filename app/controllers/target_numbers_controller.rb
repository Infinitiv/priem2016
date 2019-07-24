class TargetNumbersController < ApplicationController
  load_and_authorize_resource
  before_action :set_target_number, only: [:show, :edit, :update, :destroy]
  before_action :target_number_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :create, :edit, :update]
  def index
    @target_numbers = TargetNumber.order(:created_at)
  end
  
  def show
    
  end
  
  def new
    @target_number = TargetNumber.new
    @target_number.competitive_group_id = params[:competitive_group_id]
  end
  
  def create
    @target_number = TargetNumber.new(target_number_params)
    if @target_number.save
      redirect_to competitive_groups_url, notice: 'Target Number successfully created'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @target_number.update(target_number_params)
      redirect_to @target_number, notice: 'Target Number successfully updated'
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @target_number.destroy
    redirect_to target_numbers_path
  end
  
  private
  
  def set_target_number
    @target_number = TargetNumber.find(params[:id])
  end
  
  def target_number_params
    params.require(:target_number).permit(:competitive_group_id, :target_organization_id, :number_target_o, :number_target_oz, :number_target_z)
  end
  
  def set_selects
    @competitive_groups = CompetitiveGroup.order(:name)
    @target_organizations = params[:competitive_group_id] ?  TargetOrganization.order(:target_organization_name) - @competitive_groups.find(params[:competitive_group_id]).target_organizations : TargetOrganization.order(:target_organization_name)
  end
end
