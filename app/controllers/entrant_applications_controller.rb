class EntrantApplicationsController < ApplicationController
  load_and_authorize_resource
  before_action :set_entrant_application, only: [:show, :edit, :update, :destroy, :touch, :toggle_agreement, :toggle_original, :entrant_application_recall, :toggle_contract, :generate_templates, :approve, :add_comment, :delete_comment, :toggle_competitive_group, :delete_request, :add_document]
  before_action :set_competitive_group, only: [:toggle_agreement, :toggle_contract, :toggle_competitive_group]
  before_action :entrant_application_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit, :create, :update, :show]
  before_action :set_campaign, only: [:import, :index, :ege_to_txt, :errors, :competition_lists, :ord_export, :ord_marks_request, :competition_lists_to_html, :competition_lists_ord_to_html, :ord_return_export, :ord_result_export, :ord_access_request, :target_report, :entrants_lists_to_html, :entrants_lists_ord_to_html]
  
  def index
    @entrant_applications = EntrantApplication.includes(:education_document, :marks).select(:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :status_id, :campaign_id, :data_hash, :registration_date, :status, :comment, :email, :snils, :created_at).where(campaign_id: @campaign)
  end
  
  def show
    if @entrant_application.application_number
      entrant_applications = @entrant_application.campaign.entrant_applications.select(:id, :application_number)
      @previous_entrant = entrant_applications.find_by_application_number(@entrant_application.application_number - 1) if @entrant_application
      @next_entrant = entrant_applications.find_by_application_number(@entrant_application.application_number + 1)
    else
      entrant_applications = @entrant_application.campaign.entrant_applications.select(:id)
      @previous_entrant = entrant_applications.find_by_id(@entrant_application.id - 1)
      @next_entrant = entrant_applications.find_by_id(@entrant_application.id + 1)
    end
    @marks = @entrant_application.marks.order(:subject_id).includes(:subject)
    @sum = @marks.pluck(:value).any? ? @marks.pluck(:value).sum : 0
    @achievements = @entrant_application.achievements.includes(:institution_achievement)
    @achievements_sum = @achievements.pluck(:value).sum
    achievements_limit = 10 if @entrant_application.campaign.campaign_type_id == 1
    if achievements_limit
      @achievements_sum = @achievements_sum > achievements_limit ? 10 : @achievements_sum
    end
    @full_sum = @sum + @achievements_sum
    @entrance_test_items = @entrant_application.campaign.entrance_test_items.select(:id, :subject_id, :min_score).uniq
    @citizenship = Dictionary.find_by_code(21).items.select{|country| country.key(@entrant_application.nationality_type_id)}.first['name']
    @target_contracts = @entrant_application.target_contracts
    @journal_entries = Journal.includes(:user).where(entrant_application_id: @entrant_application.id)
    @achievement = @entrant_application.achievements.new
    @dup = @entrant_application.campaign.identity_documents.where(identity_document_series: @entrant_application.identity_documents.map(&:identity_document_series), identity_document_number: @entrant_application.identity_documents.map(&:identity_document_number))
    @dup_entrants = []
    if @dup.count > 1
      @dup.each do |identity_document|
        @dup_entrants << identity_document.entrant_application
      end
      @dup_entrants = @dup_entrants - [@entrant_application]
    end
  end
  
  def new
    @entrant_application = EntrantApplication.new
  end
  
  def create
    @entrant_application = EntrantApplication.new(entrant_application_params)
    @entrant_application.data_hash = Digest::SHA256.hexdigest [params].join()
    if @entrant_application.save
      redirect_to @entrant_application, notice: 'EntrantApplication successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @entrant_application.update(entrant_application_params)
      value_name = 'status_update'
      old_value = @entrant_application.status
      new_value = 'внесены изменения'
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
      @entrant_application.update_attributes(status_id: 2, status: new_value)
      redirect_to @entrant_application
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @entrant_application.destroy
    redirect_to "#{entrant_applications_path}?campaign_id=#{@entrant_application.campaign.id}"
  end
  
  def touch
    @entrant_application.touch
    redirect_to :back
  end
  
  def toggle_agreement
    unless @competitive_group.id == @entrant_application.exeptioned
      unless @entrant_application.enrolled.nil?
        enrolled_recall
      end
      old_value = @entrant_application.budget_agr || @entrant_application.paid_agr
      if @entrant_application.budget_agr == @competitive_group.id || @entrant_application.paid_agr == @competitive_group.id
        value_name = ('budget_arg' if @entrant_application.budget_agr) || ('paid_agr' if @entrant_application.paid_agr)
        @entrant_application.budget_agr = nil
        @entrant_application.paid_agr = nil
      else
        @entrant_application.budget_agr = nil
        @entrant_application.paid_agr = nil
        if @competitive_group.name =~ /Внебюджет/ 
          @entrant_application.paid_agr = @competitive_group.id
          value_name = 'paid_agr'
        else
          @entrant_application.budget_agr = @competitive_group.id
          value_name = 'budget_arg'
        end
      end
      new_value = @entrant_application.budget_agr || @entrant_application.paid_agr
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    end
    if @entrant_application.save!
      value_name = 'status_update'
      old_value = @entrant_application.status
      new_value = 'принято'
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: 'status_update', value_name: value_name, old_value: old_value, new_value: new_value)
      @entrant_application.update_attributes(status: new_value)
      redirect_to @entrant_application
    end
  end
  
  def toggle_contract
    if @competitive_group.education_source_id == 15
      value_name = 'contracts'
      if @entrant_application.contracts.map(&:competitive_group_id).include?(@competitive_group.id)
        old_value = @competitive_group.id
        @entrant_application.contracts.where(competitive_group_id: @competitive_group.id).destroy_all
        new_value = nil
      else
        old_value = nil
        @entrant_application.contracts.create(competitive_group_id: @competitive_group.id)
        new_value = @competitive_group.id
      end
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    end
    if @entrant_application.save!
      redirect_to @entrant_application
    end
  end
  
  def toggle_competitive_group
    if @entrant_application.competitive_groups.include? @competitive_group
      @entrant_application.competitive_groups.delete(@competitive_group)
    else
      @entrant_application.competitive_groups << @competitive_group
    end
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @entrant_application.update_attributes(status_id: 2, status: new_value)
    redirect_to @entrant_application
  end
  
  def entrant_application_recall
    old_value = @entrant_application.status_id
    @entrant_application.status_id = 6
    @entrant_application.return_documents_date = Time.now.to_date
    value_name = 'entrant_application_recall'
    new_value = @entrant_application.status_id
    if @entrant_application.save!
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
      redirect_to @entrant_application
    end
  end
  
  def toggle_original
    education_document = @entrant_application.education_document
    value_name = 'original'
    old_value = education_document.original_received_date
    if education_document.original_received_date
      education_document.original_received_date = nil
    else
      education_document.original_received_date = Time.now.to_date
    end
    new_value = education_document.original_received_date
    if education_document.save!
      Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
      @entrant_application.touch
      redirect_to @entrant_application
    end
  end
  
  def import
    EntrantApplication.import(params[:file], @campaign)
    redirect_to entrant_applications_url + "?campaign_id=#{@campaign.id}", notice: "Applications imported."
  end
  
  def ege_to_txt
    entrant_applications = EntrantApplication.includes(:identity_documents).where(campaign_id: @campaign, status_id: 4)
    ege_to_txt = EntrantApplication.ege_to_txt(entrant_applications)
    send_data ege_to_txt, :filename => "ege #{Time.now.to_date}.csv", :type => 'text/plain', :disposition => "attachment"
  end
  
  def errors
    @errors = EntrantApplication.errors(@campaign)
  end
  
  def competition_lists
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.select{|k, v| v[:summa] > 0}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit]]}.reverse
    @target_organizations = TargetOrganization.order(:target_organization_name)
  end
  
  def competition_lists_to_html
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.select{|k, v| v[:summa] > 0}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit]]}.reverse
    html = render_to_string layout: 'competition_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'competitions', filename), 'w').write(html)
    FileUtils.cp(Rails.root.join('public', 'competitions', 'current_competitions_spec.html'), Rails.root.join('public', 'competitions', 'current_competitions_spec.html.bak'))
    FileUtils.mv(Rails.root.join('public', 'competitions', filename), Rails.root.join('public', 'competitions', 'current_competitions_spec.html'))
    redirect_to :root
  end
  
  def entrants_lists_to_html
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| k.application_number}.sort_by{|k, v| k.application_number}
    html = render_to_string layout: 'entrants_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'entrants', filename), 'w').write(html)
    FileUtils.mv(Rails.root.join('public', 'entrants', filename), Rails.root.join('public', 'entrants', 'current_entrants_spec.html'))
    redirect_to :root
  end
  
  def entrants_lists_ord_to_html
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| k.application_number}.sort_by{|k, v| k.application_number}
    @target_organizations = TargetOrganization.order(:target_organization_name)
    html = render_to_string layout: 'entrants_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'entrants', filename), 'w').write(html)
    FileUtils.mv(Rails.root.join('public', 'entrants', filename), Rails.root.join('public', 'entrants', 'current_entrants_ord.html'))
    redirect_to :root
  end
  
  def competition_lists_ord_to_html
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.select{|k, v| v[:summa] > 0}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit]]}.reverse
    @target_organizations = TargetOrganization.order(:target_organization_name)
    html = render_to_string layout: 'competition_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'competitions', filename), 'w').write(html)
    FileUtils.mv(Rails.root.join('public', 'competitions', filename), Rails.root.join('public', 'competitions', 'current_competitions_ord.html'))
    redirect_to :root
  end
  
  def ord_export
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :birth_date, :nationality_type_id, :registration_date, :return_documents_date).includes(:marks, :competitive_groups, :education_document).where(return_documents_date: nil, nationality_type_id: 1, status_id: [4, 6])
    send_data EntrantApplication.ord_export(@entrant_applications), filename: "entrant_applications-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_return_export
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :birth_date, :nationality_type_id, :registration_date, :return_documents_date).includes(:competitive_groups).where.not(return_documents_date: nil).where(nationality_type_id: 1)
    send_data @entrant_applications.ord_return_export(@entrant_applications), filename: "entrant_applications_return-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_marks_request
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :birth_date, :status_id).includes(:marks, :education_document).joins(:marks).where(status_id: [2, 4], marks: {value: 0}, nationality_type_id: 1).where.not(application_number: nil)
    send_data @entrant_applications.ord_marks_request(@entrant_applications), filename: "entrant_marks_request-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_result_export
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
    send_data EntrantApplication.ord_result_export(@applications_hash), filename: "entrant_ord_result_export-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_access_request
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :birth_date, :nationality_type_id).includes(:education_document).joins(:marks).where(nationality_type_id: 1, status_id: [2, 4], marks: {form: 'Экзамен', organization_uid: '1.2.643.5.1.13.13.12.4.37.21', year: 2020})
    send_data EntrantApplication.ord_access_request(@entrant_applications), filename: "entrant_ord_access_request-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def target_report
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
    send_data EntrantApplication.target_report(@applications_hash), filename: "entrant_target_reslut_export-#{Date.today}.xml", type: 'text/xml', disposition: "attachment"
  end
  
  def generate_templates
    unless @entrant_application.application_number
      last_application_number = @entrant_application.campaign.entrant_applications.select(:id, :application_number).map(&:application_number).compact.max
      @entrant_application.application_number = last_application_number ?  last_application_number + 1 : 1
      @entrant_application.save
    end
    @entrant_application.generate_recall_application
    @entrant_application.generate_title_application
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'проверено, замечаний нет'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @entrant_application.update_attributes(request: nil, comment: nil, status: new_value)
    #Events.generate_templates(@entrant_application).deliver_later if Rails.env == 'production'
    redirect_to @entrant_application
  end
  
  def approve
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'принято'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @entrant_application.update_attributes(status_id: 4, comment: nil, status: new_value)
    redirect_to :back
  end
  
  def add_comment
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'проверено, есть замечания'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    @entrant_application.update_attributes(comment: params[:comment], status: new_value)
    Events.add_comment(@entrant_application).deliver_later if Rails.env == 'production'
    redirect_to @entrant_application
  end
  
  def delete_comment
    @entrant_application.comment = nil
    @entrant_application.save
    redirect_to @entrant_application
  end
  
  def delete_request
    @entrant_application.update_attributes(request: nil)
    redirect_to @entrant_application
  end
  
  def add_document
    value_name = 'status_update'
    old_value = @entrant_application.status
    new_value = 'внесены изменения'
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, value_name: value_name, old_value: old_value, new_value: new_value)
    case params[:document_type]
    when 'Документ на льготу'
      benefit_document = @entrant_application.benefit_documents.new
      @entrant_application.update_attributes(benefit: true, status_id: 2, status: new_value) if benefit_document.save
    when 'Диплом призера олимпиады'
      olympic_document = @entrant_application.olympic_documents.new
      @entrant_application.update_attributes(olympionic: true, status_id: 2, status: new_value) if olympic_document.save
    when 'Целевой договор'
      @entrant_application.competitive_groups.where(education_source_id: 16).each do |competitive_group|
        target_contract = @entrant_application.target_contracts.new(competitive_group_id: competitive_group.id)
        @entrant_application.update_attributes(status_id: 2, status: new_value) if target_contract.save
      end
    else
      other_document = @entrant_application.other_documents.new
      @entrant_application.update_attributes(status_id: 2, status: new_value) if other_document.save
    end
    redirect_to @entrant_application
  end
  
  private
  
  def set_entrant_application
    @entrant_application = EntrantApplication.includes(:campaign, :competitive_groups, :marks, :achievements, :identity_documents, :education_document, :target_contracts, :target_organizations, :olympic_documents, :benefit_documents, :other_documents).find(params[:id])
  end
  
  def entrant_application_params
    params.require(:entrant_application).permit(:campaign_id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :gender_id, :birth_date, :region_id, :registration_date, :status_id, :nationality_type_id, :need_hostel, :special_entrant, :olympionic, :benefit, :checked, :email, :phone, :snils, :address, :snils_absent)
  end

  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
  
  def set_selects
    @target_organizations = TargetOrganization.order(:target_organization_name)
    @application_statuses = Dictionary.find_by_code(4).items
    @countries = Dictionary.find_by_code(21).items
    @benefit_document_types = [
        {
          id: 11,
          name: "Справка об установлении инвалидности"
        },
        {
          id: 30,
          name: "Документ, подтверждающий принадлежность к детям-сиротам и детям, оставшимся без попечения родителей"
        },
        {
          id: 31,
          name: "Документ, подтверждающий принадлежность к ветеранам боевых действий"
        },
        {
          id: 32,
          name: "Документ, подтверждающий наличие только одного родителя - инвалида I группы и принадлежность к числу малоимущих семей"
        },
        {
          id: 33,
          name: "Документ, подтверждающий принадлежность родителей и опекунов к погибшим в связи с исполнением служебных обязанностей"
        },
        {
          id: 34,
          name: "Документ, подтверждающий принадлежность к сотрудникам государственных органов Российской Федерации"
        },
        {
          id: 35,
          name: "Документ, подтверждающий участие в работах на радиационных объектах или воздействие радиации"
        }
        ]
    @benefit_types = [{
                        id: 4,
                        name: "По квоте приёма лиц, имеющих особое право"
                        },
                      {
                        id: 5,
                        name: "Преимущественное право на поступление"
                        }]
    @olympic_benefit_types = [{
                        id: 1,
                        name: "Зачисление без вступительных испытаний"
                        },
                      {
                        id: 3,
                        name: "Приравнивание к лицам, набравшим максимальное количество баллов по ЕГЭ"
                        }]
    @institution_achievements = @entrant_application.campaign.institution_achievements
    @documents = ['Документ на льготу', 'Диплом призера олимпиады', 'Целевой договор', 'Прочий документ']
  end
  
  def set_competitive_group
    @competitive_group = CompetitiveGroup.find(params[:competitive_group_id])
  end
  
  def enrolled_recall
    value_name = 'enrolled'
    old_value = @entrant_application.enrolled
    new_value = nil
    @entrant_application.exeptioned = @entrant_application.enrolled
    @entrant_application.exeptioned_date = Time.now.to_date
    @entrant_application.enrolled = nil
    @entrant_application.enrolled_date = nil
    Journal.create(user_id: current_user.id, entrant_application_id: @entrant_application.id, method: __method__.to_s, old_value: old_value, new_value: new_value)
    return @entrant_application
  end
end
