class EntrantApplicationsController < ApplicationController
  before_action :set_entrant_application, only: [:show, :edit, :update, :destroy, :touch]
  before_action :entrant_application_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit, :create, :update]
  before_action :set_campaign, only: [:import, :index, :ege_to_txt, :errors, :competition_lists, :ord_export, :ord_marks_request, :competition_lists_to_html, :competition_lists_ord_to_html, :ord_return_export, :ord_result_export, :target_report, :entrants_lists_to_html, :entrants_lists_ord_to_html]
  
  def index
    @entrant_applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
  end
  
  def show
    @entrant_applications_hash = EntrantApplication.entrant_applications_hash(@entrant_application.campaign).select{|k, v| v[:summa] > 0 && k.status_id == 4}.sort_by{|k, v| [v[:full_summa].to_f, v[:summa].to_f, v[:mark_values], v[:benefit]]}.reverse.to_h
    entrant_applications = @entrant_application.campaign.entrant_applications.select(:id, :application_number)
    @previous_entrant = entrant_applications.find_by_application_number(@entrant_application.application_number - 1)
    @next_entrant = entrant_applications.find_by_application_number(@entrant_application.application_number + 1)
    @marks = @entrant_application.marks
    @full_summa = @entrant_applications_hash[@entrant_application] ? @entrant_applications_hash[@entrant_application][:full_summa] : nil
    @entrance_test_items_count = @entrant_application.campaign.entrance_test_items.select(:subject_id, :min_score).uniq.size
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
      redirect_to @entrant_application
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @entrant_application.destroy
    redirect_to entrant_applications_path
  end
  
  def touch
    @entrant_application.touch
    redirect_to :back
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
    @target_organizations = TargetOrganization.order(:target_organization_name)
    html = render_to_string layout: 'competition_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'competitions', filename), 'w').write(html)
    FileUtils.mv(Rails.root.join('public', 'competitions', filename), Rails.root.join('public', 'competitions', 'current_competitions_spec.html'))
    redirect_to :root
  end
  
  def entrants_lists_to_html
    @entrance_test_items = @campaign.entrance_test_items.order(:entrance_test_priority).select(:subject_id, :min_score, :entrance_test_priority).uniq
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).sort_by{|k, v| k.application_number}
    @target_organizations = TargetOrganization.order(:target_organization_name)
    html = render_to_string layout: 'entrants_lists_to_html'
    filename = "#{@campaign.id}-#{Time.now.to_datetime.strftime("%F %T")}.html".gsub(' ', '-')
    File.open(Rails.root.join('public', 'entrants', filename), 'w').write(html)
    FileUtils.mv(Rails.root.join('public', 'entrants', filename), Rails.root.join('public', 'entrants', 'current_entrants_spec.html'))
    redirect_to :root
  end
  
  def entrants_lists_ord_to_html
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign).sort_by{|k, v| k.application_number}
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
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :birth_date, :nationality_type_id, :registration_date, :return_documents_date).includes(:marks, :competitive_groups, :education_document).where(return_documents_date: nil)
    send_data @entrant_applications.ord_export(@entrant_applications), filename: "entrant_applications-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_return_export
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :birth_date, :nationality_type_id, :registration_date, :return_documents_date).includes(:competitive_groups).where.not(return_documents_date: nil)
    send_data @entrant_applications.ord_return_export(@entrant_applications), filename: "entrant_applications_return-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_marks_request
    @entrant_applications = @campaign.entrant_applications.select(:id, :snils, :birth_date).includes(:marks, :education_document).joins(:marks).where(marks: {value: 0})
    send_data @entrant_applications.ord_marks_request(@entrant_applications), filename: "entrant_marks_request-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def ord_result_export
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
    send_data EntrantApplication.ord_result_export(@applications_hash), filename: "entrant_ord_result_export-#{Date.today}.csv", type: 'text/csv', disposition: "attachment"
  end
  
  def target_report
    @applications_hash = EntrantApplication.entrant_applications_hash(@campaign)
    send_data EntrantApplication.target_report(@applications_hash), filename: "entrant_target_reslut_export-#{Date.today}.xml", type: 'text/xml', disposition: "attachment"
  end
  
  private
  
  def set_entrant_application
    @entrant_application = EntrantApplication.includes(:campaign, :competitive_groups, :marks, :achievements, :identity_documents, :education_document).find(params[:id])
  end
  
  def entrant_application_params
    params.require(:entrant_application).permit(:campaign_id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :gender_id, :birth_date, :region_id, :registration_date, :status_id, :nationality_type_id, :need_hostel, :special_entrant, :olympionic, :benefit, :checked)
  end

  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
  
  def set_selects
    @target_organizations = TargetOrganization.order(:target_organization_name)
    @application_statuses = Dictionary.find_by_code(4).items
    @countries = Dictionary.find_by_code(7).items
  end
end
