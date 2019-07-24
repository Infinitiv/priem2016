class ApplicationController < ActionController::Base
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.new_user_session_url, notice: exception.message
  end
  protect_from_forgery with: :exception
  before_action :set_campaigns

  def set_campaigns
    @campaigns = Campaign.order(:name)
  end
end
