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
      current_registration_number = campaign.entrant_applications.select(:registration_number).map(&:registration_number).max
      entrant_application.registration_number = current_registration_number ? current_registration_number + 1 : 1
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

  end

  def update
    response_data = {}
    if params[:entrant_application]
      if params[:personal]
        response_data[:personal] = {}
        if params[:personal][:entrantLastName]
          @entrant_application.entrant_last_name = params[:personal][:entrantLastName]
          response_data[:personal][:entrantLastName] = 'success'
        end
        if params[:personal][:entrantFirstName]
          @entrant_application.entrant_first_name = params[:personal][:entrantFirstName] 
          response_data[:personal][:entrantFirstName] = 'success'
        end
        if params[:personal][:entrantMiddleName]
          @entrant_application.entrant_middle_name = params[:personal][:entrantMiddleName] 
        end
        if params[:personal][:genderId]
          @entrant_application.gender_id = params[:personal][:genderId] 
          response_data[:personal][:entrantMiddleName]  = 'success'
        end
        if params[:personal][:birthDate]
          @entrant_application.birth_date = params[:personal][:birthDate]
          response_data[:personal][:birthDate]  = 'success'
        end
      end
      if params[:needHostel]
        @entrant_application.need_hostel = params[:needHostel]
        response_data[:needHostel] = 'success'
      end
      if params[:specialEntrant]
        @entrant_application.special_entrant = params[:specialEntrant]
        response_data[:specialEntrant] = 'success'
      end
      if params[:specialConditions]
        @entrant_application.special_conditions = params[:specialConditions]
        response_data[:specialConditions] = 'success'
      end
      if params[:benefit]
        @entrant_application.benefit = params[:benefit]
        response_data[:benefit] = 'success'
      end
      if params[:olympionic]
        @entrant_application.olympionic = params[:olympionic]
        response_data[:olympionic] = 'success'
      end
      if params[:contactInformation]
        response_data[:contactInformation] = {}
        if params[:contactInformation][:address]
          @entrant_application.address = params[:contactInformation][:address]
          response_data[:contactInformation][:address] = 'success'
        end
        if params[:contactInformation][:zipCode]
          @entrant_application.zip_code = params[:contactInformation][:zipCode]
          response_data[:contactInformation][:zipCode] = 'success'
        end
        if params[:contactInformation][:phone]
          @entrant_application.phone = params[:contactInformation][:phone]
          response_data[:contactInformation][:phone] = 'success'
        end
      end
      if params[:snils]
        @entrant_application.snils = params[:snils]
        response_data[:snils] = 'success'
      end
      if params[:language]
        @entrant_application.language = params[:language]
        response_data[:language] = 'success'
      end
      if @entrant_application.save
        if params[:educationDocument]
          tmp_hash = {}
          response_data[:educationDocument] = {}
          params[:educationDocument].each{|k, v| tmp_hash[k.underscore] = v}
          keys = EducationDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            education_document = EducationDocument.find(tmp_hash['id'])
            education_document.attributes = tmp_hash
          else
            education_document = EducationDocument.new(tmp_hash)
            education_document.entrant_application_id = @entrant_application.id
          end
          education_document.save!
          response_data[:educationDocument][:id]  = education_document.id
        end
        if params[:identityDocument]
          tmp_hash = {}
          response_data[:identityDocument] = {}
          params[:identityDocument].each{|k, v| tmp_hash[k.underscore] = v}
          keys = IdentityDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            identity_document = @entrant_application.identity_documents.find(tmp_hash['id'])
            identity_document.attributes = tmp_hash
          else
            identity_document = @entrant_application.identity_documents.new(tmp_hash)
          end
          identity_document.save!
          response_data[:identityDocument][:id]  = identity_document.id
        end
        if params[:olympicDocument]
          tmp_hash = {}
          response_data[:olympicDocument] = {}
          params[:olympicDocument].each{|k, v| tmp_hash[k.underscore] = v}
          keys = OlympicDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            olympic_document = @entrant_application.olympic_documents.find(tmp_hash['id'])
            olympic_document.attributes = tmp_hash
          else
            olympic_document = @entrant_application.olympic_documents.new(tmp_hash)
          end
          olympic_document.save!
          response_data[:olympicDocument][:id]  = olympic_document.id
        end
        if params[:benefitDocument]
          tmp_hash = {}
          response_data[:benefitDocument] = {}
          params[:benefitDocument].each{|k, v| tmp_hash[k.underscore] = v}
          keys = BenefitDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            benefit_document = @entrant_application.benefit_documents.find(tmp_hash['id'])
            benefit_document.attributes = tmp_hash
          else
            benefit_document = @entrant_application.benefit_documents.new(tmp_hash)
          end
          benefit_document.save!
          response_data[:benefitDocument][:id]  = benefit_document.id
        end
        if params[:otherDocument]
          tmp_hash = {}
          response_data[:otherDocument] = {}
          params[:otherDocument].each{|k, v| tmp_hash[k.underscore] = v}
          keys = OtherDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            other_document = @entrant_application.other_documents.find(tmp_hash['id'])
            other_document.attributes = tmp_hash
          else
            other_document = @entrant_application.other_documents.new(tmp_hash)
          end
          other_document.save!
          response_data[:otherDocument][:id]  = other_document.id
        end
        if params[:targetContract]
          tmp_hash = {}
          response_data[:targetContract] = {}
          params[:targetContract].each{|k, v| tmp_hash[k.underscore] = v}
          keys = TargetContract.new.attributes.keys
          tmp_hash.slice! *keys
          tmp_hash['target_organization_id'] = CompetitiveGroup.find(tmp_hash['competitive_group_id']).target_organizations.first.id
          if tmp_hash['id']
            target_contract = @entrant_application.target_contracts.find(tmp_hash['id'])
            target_contract.attributes = tmp_hash
          else
            target_contract = @entrant_application.target_contracts.new(tmp_hash)
          end
          target_contract.save!
          response_data[:targetContract][:id]  = target_contract.id
        end
        if params[:mark]
          tmp_hash = {}
          response_data[:mark] = {}
          params[:mark].each{|k, v| tmp_hash[k.underscore] = v}
          keys = Mark.new.attributes.keys
          tmp_hash.slice! *keys
          if tmp_hash['id']
            mark = @entrant_application.marks.find(tmp_hash['id'])
            mark.attributes = tmp_hash
          else
            mark = @entrant_application.marks.new(tmp_hash)
          end
          mark.save!
          response_data[:mark][:id]  = mark.id
        end
        if params[:competitiveGroup]
          response_data[:competitiveGroup] = {}
          @entrant_application.competitive_groups.delete_all
          @entrant_application.competitive_groups << CompetitiveGroup.where(id: params[:competitiveGroup])
          response_data[:competitiveGroup][:ids]  = @entrant_application.competitive_groups.map(&:id)
        end
        if params[:achievement]
          response_data[:achievement] = {}
          params[:achievement].each do |institution_achievement_id|
            @entrant_application.achievements.create(institution_achievement_id: institution_achievement_id)
          end
          response_data[:achievement][:ids]  = @entrant_application.achievements.map(&:institution_achievement_id)
        end
        #if params[:other_documents]
          #params[:other_documents].each do |other_document|
            #unless other_document[:other_document_number] == ''
              #@entrant_application.other_documents.create(other_document)
            #end
          #end
        #end
      response_data[:status] = 'success'
      response_data[:hash] = @entrant_application.data_hash
      send_data(response_data.to_json)
      end
    end
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
end
