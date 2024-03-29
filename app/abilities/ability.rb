class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?
    can :read, Campaign
    return unless user.clerk?
    can [:read, :toggle_agreement, :toggle_original, :entrant_application_recall, :toggle_contract, :destroy, :approve, :generate_templates, :add_comment, :delete_comment, :update, :delete_request, :add_document], EntrantApplication
    can [:update], IdentityDocument
    can [:update], EducationDocument
    can [:update], TargetContract
    can [:update, :convert_to_other_document], OlympicDocument
    can [:update, :convert_to_other_document], BenefitDocument
    can [:show], Attachment
    can [:update], Mark
    can [:manage], Ticket
    return unless user.super?
    can [:manage], Achievement
    can [:manage], TargetContract
    can [:mon], Report
    can [:competition_lists, :competition_lists_to_html, :toggle_competitive_group], EntrantApplication
    can [:destroy], Attachment
    return unless user.admin?
    can :manage, :all
  end
end
