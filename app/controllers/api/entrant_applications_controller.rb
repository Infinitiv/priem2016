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
    campaign = Campaign.find(params[:campaign_id])
    if campaign.entrant_applications.where(email: params[:email]).empty?
      entrant_application = EntrantApplication.new
      current_registration_number = campaign.entrant_applications.select(:registration_number).map(&:registration_number).compact.max
      entrant_application.registration_number = current_registration_number ? current_registration_number + 1 : 1
      entrant_application.campaign_id = params[:campaign_id]
      entrant_application.email = params[:email]
      entrant_application.nationality_type_id = 1
      entrant_application.registration_date = Time.now.to_date
      entrant_application.data_hash = Digest::MD5.hexdigest [entrant_application.email, campaign.salt].compact.join()
      entrant_application.status = 'новое'
      entrant_application.status_id = 0
      entrant_application.pin = (1..9).to_a.sample(4).join().to_i
      if entrant_application.save
        entrant_application.campaign.entrance_test_items.uniq.each do |entrance_test_item|
          entrant_application.marks.create(subject_id: entrance_test_item.subject_id, value: 0)
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
    if params[:entrant_application] && @entrant_application.status_id == 0
      if params[:personal]
        response_data[:personal] = {}
        if params[:personal][:entrant_last_name]
          @entrant_application.entrant_last_name = params[:personal][:entrant_last_name]
          response_data[:personal][:entrant_last_name] = 'success'
        end
        if params[:personal][:entrant_first_name]
          @entrant_application.entrant_first_name = params[:personal][:entrant_first_name] 
          response_data[:personal][:entrant_first_name] = 'success'
        end
        if params[:personal][:entrant_middle_name]
          @entrant_application.entrant_middle_name = params[:personal][:entrant_middle_name] 
          response_data[:personal][:entrant_middle_name]  = 'success'
        end
        if params[:personal][:gender_id]
          @entrant_application.gender_id = params[:personal][:gender_id] 
          response_data[:personal][:gender_id]  = 'success'
        end
        if params[:personal][:birth_date]
          @entrant_application.birth_date = params[:personal][:birth_date]
          response_data[:personal][:birth_date]  = 'success'
        end
      end
      if params[:need_hostel]
        @entrant_application.need_hostel = params[:need_hostel]
        response_data[:need_hostel] = 'success'
      end
      if params[:special_entrant]
        @entrant_application.special_entrant = params[:special_entrant]
        response_data[:special_entrant] = 'success'
      end
      if params[:special_conditions]
        @entrant_application.special_conditions = params[:special_conditions]
        response_data[:special_conditions] = 'success'
      end
      if params[:benefit]
        @entrant_application.benefit = params[:benefit]
        response_data[:benefit] = 'success'
      end
      if params[:olympionic]
        @entrant_application.olympionic = params[:olympionic]
        response_data[:olympionic] = 'success'
      end
      if params[:contact_information]
        response_data[:contact_information] = {}
        if params[:contact_information][:address]
          @entrant_application.address = params[:contact_information][:address]
          response_data[:contact_information][:address] = 'success'
        end
        if params[:contact_information][:zip_code]
          @entrant_application.zip_code = params[:contact_information][:zip_code]
          response_data[:contact_information][:zip_code] = 'success'
        end
        if params[:contact_information][:phone]
          @entrant_application.phone = params[:contact_information][:phone]
          response_data[:contact_information][:phone] = 'success'
        end
      end
      if params[:snils]
        @entrant_application.snils = params[:snils]
        response_data[:snils] = 'success'
      end
      if params[:snils_absent]
        @entrant_application.snils_absent = params[:snils_absent]
        response_data[:snils_absent] = 'success'
      end
      if params[:language]
        @entrant_application.language = params[:language]
        response_data[:language] = 'success'
      end
      if params[:consent]
        @entrant_application.budget_agr = params[:consent][:budget_agr]
        response_data[:consent] = 'success'
      end
      if params[:status_id]
        @entrant_application.status_id = 2
        @entrant_application.status = 'на расмотрении'
        Events.welcome_mail(@entrant_application).deliver_later if Rails.env == 'production'
        response_data[:status_id] = 2
        response_data[:status] = 'на расмотрении'
      end
      if @entrant_application.save
        if params[:education_document]
          tmp_hash = {}
          params[:education_document].each{|k, v| tmp_hash[k] = v}
          response_data[:education_document] = {}
          keys = EducationDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:education_document][:id]
            education_document = EducationDocument.find(params[:education_document][:id])
            education_document.attributes = tmp_hash
          else
            education_document = EducationDocument.new(tmp_hash)
            education_document.entrant_application_id = @entrant_application.id
          end
          education_document.save!
          response_data[:education_document][:id]  = education_document.id
        end
        if params[:identity_document]
          tmp_hash = {}
          params[:identity_document].each{|k, v| tmp_hash[k] = v}
          response_data[:identity_document] = {}
          keys = IdentityDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:identity_document][:id]
            identity_document = @entrant_application.identity_documents.find(params[:identity_document][:id])
            identity_document.attributes = tmp_hash
          else
            identity_document = @entrant_application.identity_documents.new(tmp_hash)
          end
          identity_document.save!
          response_data[:identity_document][:id]  = identity_document.id
        end
        if params[:olympic_document]
          tmp_hash = {}
          params[:olympic_document].each{|k, v| tmp_hash[k] = v}
          response_data[:olympic_document] = {}
          keys = OlympicDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:olympic_document][:id]
            olympic_document = @entrant_application.olympic_documents.find(params[:olympic_document][:id])
            olympic_document.attributes = tmp_hash
          else
            olympic_document = @entrant_application.olympic_documents.new(tmp_hash)
          end
          olympic_document.save!
          response_data[:olympic_document][:id]  = olympic_document.id
        end
        if params[:benefit_document]
          tmp_hash = {}
          params[:benefit_document].each{|k, v| tmp_hash[k] = v}
          response_data[:benefit_document] = {}
          keys = BenefitDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:benefit_document][:id]
            benefit_document = @entrant_application.benefit_documents.find(params[:benefit_document][:id])
            benefit_document.attributes = tmp_hash
          else
            benefit_document = @entrant_application.benefit_documents.new(tmp_hash)
          end
          benefit_document.save!
          response_data[:benefit_document][:id]  = benefit_document.id
        end
        if params[:other_document]
          tmp_hash = {}
          params[:other_document].each{|k, v| tmp_hash[k] = v}
          response_data[:other_document] = {}
          keys = OtherDocument.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:other_document][:id]
            other_document = @entrant_application.other_documents.find(params[:other_document][:id])
            other_document.attributes = tmp_hash
          else
            other_document = @entrant_application.other_documents.new(tmp_hash)
          end
          other_document.save!
          response_data[:other_document][:id]  = other_document.id
        end
        if params[:target_contract]
          tmp_hash = {}
          params[:target_contract][:target_organization_id] = CompetitiveGroup.find(params[:target_contract][:competitive_group_id]).target_organizations.first.id
          params[:target_contract].each{|k, v| tmp_hash[k] = v}
          response_data[:target_contract] = {}
          keys = TargetContract.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:target_contract][:id]
            target_contract = @entrant_application.target_contracts.find(params[:target_contract][:id])
            target_contract.attributes = tmp_hash
          else
            target_contract = @entrant_application.target_contracts.new(tmp_hash)
          end
          target_contract.save!
          response_data[:target_contract][:id]  = target_contract.id
        end
        if params[:mark]
          tmp_hash = {}
          params[:mark].each{|k, v| tmp_hash[k] = v}
          response_data[:mark] = {}
          keys = Mark.new.attributes.keys
          tmp_hash.slice! *keys
          if params[:mark][:id]
            mark = @entrant_application.marks.find(params[:mark][:id])
            mark.attributes = tmp_hash
          else
            mark = @entrant_application.marks.new(tmp_hash)
          end
          mark.save!
          response_data[:mark][:id]  = mark.id
        end
        if params[:competitive_group]
          response_data[:competitive_group] = {}
          @entrant_application.competitive_groups.delete_all
          @entrant_application.competitive_groups << CompetitiveGroup.where(id: params[:competitive_group])
          response_data[:competitive_groups]  = @entrant_application.competitive_groups
        end
        if params[:achievement]
          response_data[:achievement] = {}
          params[:achievement].each do |institution_achievement_id|
            @entrant_application.achievements.create(institution_achievement_id: institution_achievement_id)
          end
          response_data[:achievements]  = @entrant_application.achievements
        end
      response_data[:result] = 'success'
      response_data[:hash] = @entrant_application.data_hash
      send_data(response_data.to_json)
      end
    else
      send_data({status: 'faild', message: 'Редактирование невозможно'}.to_json)
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
      send_data({status: 'faild', message: 'pins was not removed', hash: @entrant_application.data_hash}.to_json)
    end
  end
  
  def generate_entrant_application
    entrant_application = EntrantApplication.find_by_data_hash(params[:id])
    if entrant_application.generate_entrant_application
      send_data({status: 'success', message: 'Бланк заявления создан', attachments: entrant_application.attachments}.to_json)
    else
      send_data({status: 'faild', message: 'Что-то пошло не так'}.to_json)
    end
  end
  
  def generate_consent_applications
    entrant_application = EntrantApplication.find_by_data_hash(params[:id])
    if entrant_application.generate_consent_applications
      send_data({status: 'success', message: 'Бланки заявлений о согласии созданы', attachments: entrant_application.attachments}.to_json)
    else
      send_data({status: 'faild', message: 'Что-то пошло не так'}.to_json)
    end
  end
  
  def generate_withdraw_applications
    entrant_application = EntrantApplication.find_by_data_hash(params[:id])
    if entrant_application.generate_withdraw_applications
      send_data({status: 'success', message: 'Бланки заявлений об отзыве согласия созданы', attachments: entrant_application.attachments}.to_json)
    else
      send_data({status: 'faild', message: 'Что-то пошло не так'}.to_json)
    end
  end
  
  private
  
  def set_entrant_application
    @entrant_application = EntrantApplication.includes(:identity_documents, :education_document, :marks, :achievements, :olympic_documents, :benefit_documents, :other_documents, :competitive_groups, :target_contracts, :contracts, :attachments).find_by_data_hash(params[:id])
  end
end
