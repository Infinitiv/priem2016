class TargetContractsController < ApplicationController
  load_and_authorize_resource
  before_action :set_target_contract, only: [:update, :destroy]
  
  def update
    @target_contract.update(target_contract_params)
    @target_contract.entrant_application.update_attributes(status_id: 2)
    redirect_to :back
  end
  
  def destroy
    @target_contract.destroy
    redirect_to :back
  end
  
  private
  
  def set_target_contract
    @target_contract = TargetContract.find(params[:id])
  end
  
  def target_contract_params
    params.require(:target_contract).permit(:id, :target_organization_id)
  end
end
