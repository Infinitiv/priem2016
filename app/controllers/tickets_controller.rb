class TicketsController < ApplicationController
  load_and_authorize_resource param_method: :set_params
  before_action :set_ticket, only: [:solve]
  before_action :set_ticket_params, only: [:create]
  
  def create
    @ticket = Ticket.create(set_ticket_params)
    redirect_to :back
  end
  
  def solve
    @ticket.update_attributes(solved: true)
    redirect_to :back
  end
  
  private
  
  def set_ticket
    @ticket = Ticket.find(params[:id])
  end
  
  def set_ticket_params
    params.permit(:parent_ticket, :message, :entrant_application_id, :user_id)    
  end
end
