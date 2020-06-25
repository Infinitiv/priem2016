class Api::EntrantApplicationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def show
    @entrant_application = EntrantApplication.includes(:identity_documents, :education_document, :marks, :achievements, :olympic_documents, :benefit_documents, :competitive_groups, :target_contracts, :contracts, :attachments).find_by_data_hash(params[:id])
    @marks = @entrant_application.marks.order(:subject_id).includes(:subject)
    @sum = @marks.pluck(:value).any? ? @marks.pluck(:value).sum : 0
    @achievements = @entrant_application.achievements.includes(:institution_achievement)
    @achievements_sum = @achievements.pluck(:value).sum
    achievements_limit = 10 if @entrant_application.campaign.campaign_type_id == 1
    if achievements_limit
      @achievements_sum = @achievements_sum > achievements_limit ? 10 : @achievements_sum
    end
    @full_sum = @sum + @achievements_sum
  end
  
  def create
    @entrant_application = EntrantApplication.new
    @entrant_application.campaign_id = entrant_application_params[:campaign_id]
    @entrant_application.entrant_last_name = entrant_application_params[:entrant_last_name]
    @entrant_application.entrant_first_name = entrant_application_params[:entrant_first_name]
    @entrant_application.entrant_middle_name = entrant_application_params[:entrant_middle_name]
    @entrant_application.gender_id = entrant_application_params[:gender_id]
    @entrant_application.birth_date = entrant_application_params[:birth_date]
    @entrant_application.email = entrant_application_params[:email]
    @entrant_application.need_hostel = entrant_application_params[:need_hostel]
    @entrant_application.special_entrant = entrant_application_params[:special_entrant]
    @entrant_application.registration_date = Time.now.to_date
    @entrant_application.nationality_type_id = 1 if entrant_application_params[:citizenship]
    @entrant_application.olympionic = true unless entrant_application_params[:olympic_documents].map{|item| item.values.join()}.join() == ''
    @entrant_application.benefit = true unless entrant_application_params[:benefit_documents].map{|item| item.values.join()}.join() == ''
    @entrant_application.data_hash = Digest::MD5.hexdigest entrant_application_params.values.join()
    @entrant_application.address = entrant_application_params[:address]
    @entrant_application.zip_code = entrant_application_params[:zip_code]
    @entrant_application.phone = entrant_application_params[:phone]
    @entrant_application.email = entrant_application_params[:email]
    @entrant_application.special_conditions = entrant_application_params[:special_conditions]
    @entrant_application.status = 'новое'
    if @entrant_application.save
      education_document = EducationDocument.new(entrant_application_params[:education_document])
      education_document.entrant_application_id = @entrant_application.id
      education_document.save
      entrant_application_params[:identity_documents].each do |identity_document|
        @entrant_application.identity_documents.create(identity_document)
      end
      entrant_application_params[:marks].each do |mark|
        mark[:value] = 0
        @entrant_application.marks.create(mark)
      end
      entrant_application_params[:competitive_groups].each do |competitive_group|
        @entrant_application.competitive_groups << CompetitiveGroup.find(competitive_group[:id])
        @entrant_application.target_contracts.create(competitive_group_id: competitive_group[:id], target_organization_id: competitive_group[:target_organization_id]) if competitive_group[:target_organization_id]
      end
      if entrant_application_params[:institution_achievement_ids]
        entrant_application_params[:institution_achievement_ids].each do |institution_achievement_id|
          @entrant_application.achievements.create(institution_achievement_id: institution_achievement_id)
        end
      end
      entrant_application_params[:olympic_documents].each do |olympic_document|
        unless olympic_document[:olympic_document_type_id] == ''
          @entrant_application.olympic_documents.create(olympic_document)
        end
      end
      entrant_application_params[:benefit_documents].each do |benefit_document|
        if benefit_document[:benefit_document_type_id]
          @entrant_application.benefit_documents.create(benefit_document)
        end
      end
    end
    Events.welcome_mail(@entrant_application).deliver_later if Rails.env == 'production'
    send_data({status: 'success', hash: @entrant_application.data_hash}.to_json)
  end
  
  private
  
  def entrant_application_params
    params.permit(:citizenship, 
                  :campaign_id, 
                  :entrant_last_name, 
                  :entrant_first_name, 
                  :entrant_middle_name, 
                  :gender_id, 
                  :birth_date, 
                  :address,
                  :zip_code,
                  :email,
                  :phone,
                  :need_hostel, 
                  :special_entrant, 
                  :special_conditions,
                  identity_documents: [
                                       :identity_document_type,
                                       :identity_document_series,
                                       :identity_document_number,
                                       :identity_document_date,
                                       :identity_document_issuer,
                                       :alt_entrant_last_name,
                                       :alt_entrant_first_name,
                                       :alt_entrant_middle_name
                                       ],
                  education_document: [
                                       :education_document_type,
                                       :education_document_number,
                                       :education_document_issuer,
                                       :education_document_date
                                       ],
                  institution_achievement_ids: [],
                  marks: [
                          :subject_id,
                          :form,
                          :year,
                          :value
                          ],
                  competitive_groups: [
                                       :id,
                                       :target_organization_id
                                       ],
                  benefit_documents: [
                                      :benefit_document_type_id,
                                      :benefit_document_series,
                                      :benefit_document_number,
                                      :benefit_document_organization,
                                      :benefit_document_date
                                      ],
                  olympic_documents: [
                                         :olympic_document_type_id,
                                         :diploma_type_id,
                                         :olympic_document_series,
                                         :olympic_document_number,
                                         :olympic_document_date,
                                         :class_number
                                         ])
  end
end
