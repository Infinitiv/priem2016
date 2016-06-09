class AdmissionVolumesController < ApplicationController
  before_action :set_admission_volume, only: [:show, :edit, :update, :destroy]
  before_action :admission_volume_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :create, :edit, :update]
  def index
    @admission_volumes = AdmissionVolume.order(:created_at)
  end
  
  def show
    
  end
  
  def new
    @admission_volume = AdmissionVolume.new
  end
  
  def create
    @admission_volume = AdmissionVolume.new(admission_volume_params)
    if @admission_volume.save
      redirect_to @admission_volume, notice: 'Admission volume successfully created'
    else
      render action: 'new'
    end
  end
  
  def edit
    
  end
  
  def update
    if @admission_volume.update(admission_volume_params)
      redirect_to @admission_volume, notice: 'Admission volume successfully updated'
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @admission_volume.destroy
    redirect_to admission_volumes_path
  end
  
  private
  
  def set_admission_volume
    @admission_volume = AdmissionVolume.find(params[:id])
  end
  
  def admission_volume_params
    params.require(:admission_volume).permit(:id, :campaign_id, :education_level_id, :direction_id, :number_budget_o, :number_budget_oz, :number_budget_z, :number_paid_o, :number_paid_oz, :number_paid_z, :number_target_o, :number_target_oz, :number_target_z, :number_quota_o, :number_quota_oz, :number_quota_z)
  end
  
  def set_selects
    @campaigns = Campaign.order(:created_at).select(:id, :name, :year_start)
    @education_levels = {'Специалитет' => 5,
                        'Кадры высшей квалификации' => 18
                       }
    @directions = {'Лечебное дело' => 17509,
                   'Педиатрия' => 17353,
                  'Стоматология' => 17247}
  end
end