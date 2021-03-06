class TicketsController < ApplicationController
  load_and_authorize_resource param_method: :set_params
  before_action :set_ticket, only: [:solve]
  before_action :set_campaign, only: [:index]
  before_action :set_ticket_params, only: [:create]
  
  def index
    @tickets = Ticket.joins(:entrant_application).where(entrant_applications: {campaign_id: @campaign.id}).order(:solved, :created_at)
  end
  
  def create
    @ticket = Ticket.create(set_ticket_params)
    Events.ticket_answer(@ticket).deliver_later if Rails.env == 'production'
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
  
  
  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
  
  def set_ticket_params
    params.permit(:parent_ticket, :message, :entrant_application_id, :user_id)    
  end
end
