class DistributedAdmissionVolumesController < ApplicationController
  before_action :set_distributed_admission_volume, only: [:show, :edit, :update, :destroy]
  before_action :distributed_admission_volume_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :create, :edit, :update]
  def index
    @distributed_admission_volumes = DistributedAdmissionVolume.order(:created_at)
  end
  
  def show
    
  end
  
  def new
    @distributed_admission_volume = DistributedAdmissionVolume.new
  end
  
  def create
    @distributed_admission_volume = DistributedAdmissionVolume.new(distributed_admission_volume_params)
    if @distributed_admission_volume.save
      redirect_to @distributed_admission_volume, notice: 'Distributed admission volume successfully created'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @distributed_admission_volume.update(distributed_admission_volume_params)
      redirect_to @distributed_admission_volume, notice: 'Distributed admission volume successfully updated'
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @distributed_admission_volume.destroy
    redirect_to distributed_admission_volumes_path
  end
  
  def admission_volume_to_json
    @admission_volume = AdmissionVolume.where(id: params[:id])
    respond_to do |format|
      format.json {render json: @admission_volume.to_json}
    end
  end
  
  private
  
  def set_distributed_admission_volume
    @distributed_admission_volume = DistributedAdmissionVolume.find(params[:id])
  end
  
  def distributed_admission_volume_params
    params.require(:distributed_admission_volume).permit(:id, :admission_volume_id, :level_budget_id, :number_budget_o, :number_budget_oz, :number_budget_z, :number_target_o, :number_target_oz, :number_target_z, :number_quota_o, :number_quota_oz, :number_quota_z)
  end
  
  def set_selects
    @admission_volumes = AdmissionVolume.order(:created_at).includes(:campaign).select(:id, :campaign_id, :direction_id)
    @levels_budgets = {'Федеральный' => 1,
                       'Региональный' => 2,
                       'Муниципальный' => 3}
  end
end