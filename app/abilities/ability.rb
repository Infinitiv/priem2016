class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    can :read, Campaign
    return unless user.clerk?
    can [:read, :toggle_agreement, :toggle_original, :entrant_application_recall, :toggle_contract, :destroy, :approve, :generate_templates, :add_comment, :delete_comment], EntrantApplication
    return unless user.super?
    can [:mon], Report
    can [:competition_lists, :competition_lists_to_html], EntrantApplication
    return unless user.admin?
    can :manage, :all
  end
end
