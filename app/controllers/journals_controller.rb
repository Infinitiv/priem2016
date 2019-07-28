class JournalsController < ApplicationController
  load_and_authorize_resource
  before_action :set_journal, only: [:destroy, :done]
  
  def index
    @journals = Journal.includes(:entrant_application).order(:created_at).where(done: false).sort_by{|journal| journal.entrant_application.application_number}
  end
  
  def destroy
    @journal.destroy
    redirect_to :back
  end
  
  def done
    @journal.update_attributes(done: true)
    redirect_to :back
  end
  
  private
  
  def set_journal
    @journal = Journal.find(params[:id])
  end
end
