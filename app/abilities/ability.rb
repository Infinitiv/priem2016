class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    can :read, Campaign
    return unless user.clerk?
    can :read, EntrantApplication
    return unless user.super?
    can :read, Report
    return unless user.admin?
    can :manage, :all 
  end
end
