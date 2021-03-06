class TargetOrganizationsController < ApplicationController
  load_and_authorize_resource param_method: :set_params
  before_action :set_target_organization, only: [:show, :edit, :update, :destroy]
  before_action :target_organization_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit, :index]
  
  def index
    @target_organizations = TargetOrganization.order('created_at DESC')
  end
  
  def show
  end
  
  def new
    @target_organization = TargetOrganization.new
  end
  
  def create
    @target_organization = TargetOrganization.new(target_organization_params)
    if @target_organization.save
      redirect_to @target_organization, notice: 'Target Organization successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @target_organization.update(target_organization_params)
      redirect_to target_organizations_url
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @target_organization.destroy
    redirect_to target_organizations_path
  end
  
  private
  
  def set_target_organization
    @target_organization = TargetOrganization.find(params[:id])
  end
  
  def target_organization_params
    params.require(:target_organization).permit(:target_organization_name, :region_id)
  end
  
  def set_selects
    @regions = Dictionary.find(8).items
  end
end
