class Api::EntrantApplicationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :set_entrant_application, only: [:show, :update, :check_pin, :remove_pin]
  
  def show
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
    campaign = Campaign.find(params[:campaignId])
    if campaign.entrant_applications.where(email: params[:email]).empty?
      entrant_application = EntrantApplication.new
      entrant_application.campaign_id = params[:campaignId]
      entrant_application.email = params[:email]
      entrant_application.registration_date = Time.now.to_date
      entrant_application.data_hash = Digest::MD5.hexdigest [entrant_application.email, campaign.salt].compact.join()
      entrant_application.status = 'новое'
      entrant_application.pin = (1..9).to_a.sample(4).join().to_i
      if entrant_application.save
        entrant_application.campaign.entrance_test_items.uniq.each do |entrance_test_item|
          entrant_application.marks.create(subject_id: entrance_test_item.subject_id)
        end
        Events.check_pin(entrant_application).deliver_later if Rails.env == 'production'
        send_data({status: 'success', message: 'entrant application created', hash: entrant_application.data_hash, id: entrant_application.id}.to_json)
      end
    else
      send_data({status: 'faild', message: 'email is not uniq'}.to_json)
    end

    #@entrant_application = EntrantApplication.new
    #@entrant_application.campaign_id = entrant_application_params[:campaign_id]
    #@entrant_application.entrant_last_name = entrant_application_params[:entrant_last_name]
    #@entrant_application.entrant_first_name = entrant_application_params[:entrant_first_name]
    #@entrant_application.entrant_middle_name = entrant_application_params[:entrant_middle_name]
    #@entrant_application.gender_id = entrant_application_params[:gender_id]
    #@entrant_application.birth_date = entrant_application_params[:birth_date]
    #@entrant_application.email = entrant_application_params[:email]
    #@entrant_application.need_hostel = true if entrant_application_params[:need_hostel]
    #@entrant_application.special_entrant = entrant_application_params[:special_entrant]
    #@entrant_application.registration_date = Time.now.to_date
    #@entrant_application.nationality_type_id = 1 if entrant_application_params[:citizenship]
    #if entrant_application_params[:olympic_documents]
      #@entrant_application.olympionic = true unless entrant_application_params[:olympic_documents].map{|item| item.values.join()}.join() == ''
    #end
    #if entrant_application_params[:benefit_documents]
      #@entrant_application.benefit = true unless entrant_application_params[:benefit_documents].map{|item| item.values.join()}.join() == ''
    #end
    #@entrant_application.data_hash = Digest::MD5.hexdigest entrant_application_params.values.join()
    #@entrant_application.address = entrant_application_params[:address]
    #@entrant_application.zip_code = entrant_application_params[:zip_code]
    #@entrant_application.phone = entrant_application_params[:phone]
    #@entrant_application.snils = entrant_application_params[:snils]
    #@entrant_application.special_conditions = entrant_application_params[:special_conditions]
    #@entrant_application.status = 'новое'
    #if @entrant_application.save
      #education_document = EducationDocument.new(entrant_application_params[:education_document])
      #education_document.entrant_application_id = @entrant_application.id
      #education_document.save
      #entrant_application_params[:identity_documents].each do |identity_document|
        #@entrant_application.identity_documents.create(identity_document)
      #end
      #entrant_application_params[:marks].each do |mark|
        #mark[:value] = 0
        #@entrant_application.marks.create(mark)
      #end
      #entrant_application_params[:competitive_groups].each do |competitive_group|
        #@entrant_application.competitive_groups << CompetitiveGroup.find(competitive_group[:id])
        #@entrant_application.target_contracts.create(competitive_group_id: competitive_group[:id], target_organization_id: competitive_group[:target_organization_id]) if competitive_group[:target_organization_id]
      #end
      #if entrant_application_params[:institution_achievement_ids]
        #entrant_application_params[:institution_achievement_ids].each do |institution_achievement_id|
          #@entrant_application.achievements.create(institution_achievement_id: institution_achievement_id)
        #end
      #end
      #if entrant_application_params[:olympic_documents]
        #entrant_application_params[:olympic_documents].each do |olympic_document|
          #unless olympic_document[:olympic_document_number] == ''
            #@entrant_application.olympic_documents.create(olympic_document)
          #end
        #end
      #end
      #if entrant_application_params[:benefit_documents]
        #entrant_application_params[:benefit_documents].each do |benefit_document|
          #if benefit_document[:benefit_document_type_id]
            #@entrant_application.benefit_documents.create(benefit_document)
          #end
        #end
      #end
      #if entrant_application_params[:other_documents]
        #entrant_application_params[:other_documents].each do |other_document|
          #unless other_document[:other_document_number] == ''
            #@entrant_application.other_documents.create(other_document)
          #end
        #end
      #end
    #end
    #Events.welcome_mail(@entrant_application).deliver_later if Rails.env == 'production'
    #send_data({status: 'success', hash: @entrant_application.data_hash}.to_json)
  end

  def update
    if params[:entrantApplication]
      if @entrant_application.update_Iattributes(request: params[:request])

      end
    end
    send_data({status: 'success', hash: @entrant_application.data_hash}.to_json)
  end

  def check_pin
    pin = params[:pin].to_i
    if pin == @entrant_application.pin
      @entrant_application.update_attributes(pin: nil)
      send_data({status: 'success', message: 'pins are equal', hash: @entrant_application.data_hash}.to_json)
    else
      send_data({status: 'faild', message: 'pins are not equal', hash: @entrant_application.data_hash}.to_json)
    end
  end

  def remove_pin
    if  @entrant_application.update_attributes(pin: nil)
      send_data({status: 'success', message: 'pins was removed', hash: @entrant_application.data_hash}.to_json)
    else
      send_data({status: 'faild', message: 'pins waw not removed', hash: @entrant_application.data_hash}.to_json)
    end
  end
  
  private
  
  def set_entrant_application
    @entrant_application = EntrantApplication.includes(:identity_documents, :education_document, :marks, :achievements, :olympic_documents, :benefit_documents, :other_documents, :competitive_groups, :target_contracts, :contracts, :attachments).find_by_data_hash(params[:id])
  end
  
  #def entrant_application_params
    #params.permit(entrantApplication: {
                                       #:applicationNumber,
                                       #:campaignId,
                                       #:nationalityTypeId,
                                       #personal: {
                                                  #:entrantLastName,
                                                  #:entrantFirstName,
                                                  #:entrantMiddleName,
                                                  #:genderId,
                                                  #:birthDate
                                                 #},
                                       #contactInformation: {
                                                            #:address,
                                                            #:zipCode,
                                                            #:email,
                                                            #:phone
                                                           #},
                                       #:benefit,
                                       #:olympionic,
                                       #:budgetAgr,
                                       #:paidAgr,
                                       #:statusId,
                                       #:comment,
                                       #:status,
                                       #:request,
                                       #:enrolled,
                                       #:enrolledDate,
                                       #:needHostel,
                                       #:specialEntrant,
                                       #:specialConditions,
                                       #:hash,
                                       #:snils,
                                       #:snilsAbsent,
                                       #identityDocuments:
                                      #[
                                       #{
                                        #:id,
                                        #:identityDocumentType,
                                        #:identityDocumentSeries,
                                        #:identityDocumentNumber,
                                        #:identityDocumentDate,
                                        #:identityDocumentIssuer,
                                        #:status,
                                        #:identityDocumentData,
                                        #:altEntrantLastName,
                                        #:altEntrantFirstName,
                                        #:altEntrantMiddleName
                                       #}
                                      #],
                                       #educationDocument:
                                      #{
                                       #:id,
                                       #:educationDocumentType,
                                       #:educationDocumentNumber,
                                       #:educationDocumentDate,
                                       #:educationDocumentIssuer,
                                       #:originalReceivedDate,
                                       #:educationSpecialityCode,
                                       #:status,
                                       #:isOriginal
                                      #},
                                       #marks:
                                      #[
                                       #{
                                        #:id,
                                        #:value,:
                                        #:subjectId,
                                        #:subject,
                                        #:form,
                                        #:checked,
                                        #:organizationUid
                                       #}
                                      #],
                                       #:sum,
                                       #:achievementsSum,
                                       #:fullSum,
                                       #achievements:
                                      #[
                                       #{
                                        #:id,
                                        #:name,
                                        #:value,
                                        #:status
                                       #}
                                      #],
                                       #olympicDocuments:
                                      #[
                                       #{
                                        #:id,
                                        #:benefitDocumentTypeId,
                                        #:olympicId,
                                        #:diplomaTypeId,
                                        #:olympicProfileId,
                                        #:classNumber,
                                        #:olympicDocumentSeries,
                                        #:olympicDocumentNumber,
                                        #:olympicDocumentDate,
                                        #:olympicSubjectId,
                                        #:ege_subjectId,
                                        #:status,
                                        #:olympicDocumentTypeId
                                       #}
                                      #],
                                       #benefitDocuments:
                                      #[
                                       #{
                                        #:id,
                                        #:benefitDocumentTypeId,
                                        #:benefitDocumentSeries,
                                        #:benefitDocumentNumber,
                                        #:benefitDocumentDate,
                                        #:benefitDocumentOrganization,
                                        #:benefitTypeId,
                                        #:status
                                       #}
                                      #],
                                       #otherDocuments:
                                      #[
                                       #{
                                        #:id,
                                        #:otherDocumentSeries,
                                        #:otherDocumentNumber,
                                        #:otherDocumentIssuer,
                                        #:name
                                       #}
                                      #],
                                       #competitiveGroups:
                                      #[
                                       #{
                                        #:id,
                                        #:name,
                                        #:educationLevelId,
                                        #:educationSourceId,
                                        #:educationFormId,
                                        #:directionId
                                       #}
                                      #],
                                       #targetContracts:
                                      #[
                                       #{
                                        #:id,
                                        #:competitiveGroupId,
                                        #:competitiveGroupName,
                                        #:targetOrganizationId,
                                        #:targetOrganizationName,
                                        #:status
                                       #}
                                      #],
                                       #contracts:
                                      #[
                                       #{
                                        #:competitiveGroupId,
                                        #:competitiveGroupName,
                                        #:status
                                       #}
                                      #],
                                       #attachments:
                                      #[
                                       #{
                                        #:id,
                                        #:documentType,
                                        #:mimeType,
                                        #:dataHash,
                                        #:status,
                                        #:merged,
                                        #:template,
                                        #:documentId,
                                        #:filename
                                       #}
                                      #]
                                      #}
  #end
end
