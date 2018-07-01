class EntrantApplicationsController < ApplicationController
  before_action :set_entrant_application, only: [:show, :edit, :update, :destroy]
  before_action :entrant_application_params, only: [:create, :update]
  before_action :set_selects, only: [:new, :edit, :create, :update]
  before_action :set_campaign, only: [:import, :index, :ege_to_txt, :errors, :competition, :competition_lists]
  
  def index
    entrant_applications = @campaign.entrant_applications.select([:id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :campaign_id, :status_id]).order(:application_number).includes(:institution_achievements, :education_document)
    
    marks = Mark.joins(:entrant_application).where(entrant_applications: {id: entrant_applications.map(&:id)}).group_by(&:entrant_application_id).map{|a, ms| {a => ms.map{|m| m.value}}}.inject(:merge)
    
    achievements = {}
    InstitutionAchievement.select(:id, :max_value).each{|i| achievements[i] = i.entrant_applications.map(&:id)}
    
    @entrant_applications_hash = {}
    entrant_applications.each do |entrant_application|
      @entrant_applications_hash[entrant_application] = {}
      summa = marks[entrant_application.id].select{|i| i > 41}.size == 3 ? marks[entrant_application.id].sum : 0
      @entrant_applications_hash[entrant_application][:summa] = summa
      @entrant_applications_hash[entrant_application][:achievements] = []
      achievements.each do |i, a|
        @entrant_applications_hash[entrant_application][:achievements] << i.max_value if a.include?(entrant_application.id)
      end
      achievement_sum = @entrant_applications_hash[entrant_application][:achievements].sum
      @entrant_applications_hash[entrant_application][:achievement] = achievement_sum > 10 ? 10 : achievement_sum
      summa > 0 ? @entrant_applications_hash[entrant_application][:full_summa] = [@entrant_applications_hash[entrant_application][:summa], @entrant_applications_hash[entrant_application][:achievement]].sum : @entrant_applications_hash[entrant_application][:full_summa] = '-'
      @entrant_applications_hash[entrant_application][:original_received] = true if entrant_application.education_document.original_received_date
      @entrant_applications_hash[entrant_application][:last_deny_day] = true if entrant_application.status_id == 6
    end
  end
  
  def show
    @marks = @entrant_application.marks
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
  
  def import
    EntrantApplication.import(params[:file], @campaign)
    redirect_to entrant_applications_url + "?campaign_id=#{@campaign.id}", notice: "Applications imported."
  end
  
  def ege_to_txt
    entrant_applications = EntrantApplication.includes(:identity_documents).where(campaign_id: @campaign, status_id: 4)
    ege_to_txt = EntrantApplication.ege_to_txt(entrant_applications)
    send_data ege_to_txt, :filename => "ege #{Time.now.to_date}.csv", :type => 'text/plain', :disposition => "attachment"
  end
  
  def blue
    @entrant_applications = EntrantApplication.order(:application_number).includes(:competitive_groups)
    @achievements = {}
    InstitutionAchievement.all.each do |i|
      i.entrant_applications.each do |a|
        @achievements[a.id] =+ i.max_value
        @achievements[a.id] = 10 if @achievements[a.id] > 10
      end
    end
    respond_to do |format|
      format.xls
    end
  end
  
  def errors
    @errors = EntrantApplication.errors(@campaign)
  end
  
  def competition_lists
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.applications_hash(@campaign)
    @target_organizations = TargetOrganization.order(:target_organization_name)
  end
  
  def competition
    @admission_volume_hash = EntrantApplication.admission_volume_hash(@campaign)
    @applications_hash = EntrantApplication.applications_hash(@campaign)
    @target_organizations = TargetOrganization.order(:target_organization_name)
  end
  
  private
  
  def set_entrant_application
    @entrant_application = EntrantApplication.find(params[:id])
  end
  
  def entrant_application_params
    params.require(:entrant_application).permit(:campaign_id, :application_number, :entrant_last_name, :entrant_first_name, :entrant_middle_name, :gender_id, :birth_date, :region_id, :registration_date, :status_id, :nationality_type_id, :need_hostel, :special_entrant, :olympionic, :benefit, :checked)
  end

  def set_campaign
    @campaign = @campaigns.find(params[:campaign_id])
  end
  
  def set_selects
    @target_organizations = TargetOrganization.order(:target_organization_name)
    @application_statuses = {'Принято' => 4,
                             'Редактируется' => 1,
                             'Отозвано' => 6,
                             'Новое' => 2,
                             'Не прошедшее проверку' => 3,
                             'В приказе' => 8}
    @countries = {"АБХАЗИЯ"=>"223", "АВСТРАЛИЯ"=>"9", "АВСТРИЯ"=>"10", "АЗЕРБАЙДЖАН"=>"226", "АЛБАНИЯ"=>"229", "АЛЖИР"=>"3", "АМЕРИКАНСКОЕ САМОА"=>"4", "АНГИЛЬЯ"=>"169", "АНГОЛА"=>"6", "АНДОРРА"=>"5", "АНТИГУА И БАРБУДА"=>"7", "АРГЕНТИНА"=>"8", "АРМЕНИЯ"=>"13", "АРУБА"=>"139", "АФГАНИСТАН"=>"230", "БАГАМЫ"=>"11", "БАНГЛАДЕШ"=>"12", "БАРБАДОС"=>"14", "БЕЛАРУСЬ"=>"29", "БЕЛИЗ"=>"21", "БЕЛЬГИЯ"=>"15", "БЕНИН"=>"53", "БЕРМУДЫ"=>"16", "БОЛГАРИЯ"=>"26", "БОЛИВИЯ"=>"238", "БОСНИЯ И ГЕРЦЕГОВИНА"=>"231", "БОТСВАНА"=>"18", "БРАЗИЛИЯ"=>"20", "БРИТАНСКАЯ ТЕРРИТОРИЯ В ИНДИЙСКОМ ОКЕАНЕ"=>"22", "БРУНЕЙ-ДАРУССАЛАМ"=>"25", "БУРКИНА-ФАСО"=>"218", "БУРУНДИ"=>"28", "БУТАН"=>"17", "ВАНУАТУ"=>"141", "ВЕНГРИЯ"=>"90", "ВЕНЕСУЭЛА"=>"228", "ВИРГИНСКИЕ ОСТРОВА, БРИТАНСКИЕ"=>"24", "ВИРГИНСКИЕ ОСТРОВА, США"=>"217", "ВЬЕТНАМ"=>"183", "ГАБОН"=>"72", "ГАИТИ"=>"86", "ГАЙАНА"=>"85", "ГАМБИЯ"=>"74", "ГАНА"=>"76", "ГВАДЕЛУПА"=>"81", "ГВАТЕМАЛА"=>"83", "ГВИНЕЯ"=>"84", "ГВИНЕЯ-БИСАУ"=>"162", "ГЕРМАНИЯ"=>"75", "ГЕРНСИ"=>"212", "ГИБРАЛТАР"=>"77", "ГОНДУРАС"=>"89", "ГРЕНАДА"=>"80", "ГРЕНЛАНДИЯ"=>"79", "ГРЕЦИЯ"=>"78", "ГРУЗИЯ"=>"73", "ГУАМ"=>"82", "ДАНИЯ"=>"54", "ДЖЕРСИ"=>"213", "ДЖИБУТИ"=>"71", "ДОМИНИКА"=>"55", "ДОМИНИКАНСКАЯ РЕСПУБЛИКА"=>"56", "ЕГИПЕТ"=>"210", "ЗАМБИЯ"=>"222", "ЗАПАДНАЯ САХАРА"=>"188", "ЗИМБАБВЕ"=>"186", "ИЗРАИЛЬ"=>"97", "ИНДИЯ"=>"92", "ИНДОНЕЗИЯ"=>"93", "ИОРДАНИЯ"=>"103", "ИРАК"=>"95", "ИРАН, ИСЛАМСКАЯ РЕСПУБЛИКА"=>"94", "ИРЛАНДИЯ"=>"96", "ИСЛАНДИЯ"=>"91", "ИСПАНИЯ"=>"187", "ИТАЛИЯ"=>"98", "ЙЕМЕН"=>"221", "КАБО-ВЕРДЕ"=>"33", "КАЗАХСТАН"=>"102", "КАМБОДЖА"=>"30", "КАМЕРУН"=>"31", "КАНАДА"=>"32", "КАТАР"=>"164", "КЕНИЯ"=>"104", "КИПР"=>"51", "КИРГИЗИЯ"=>"108", "КИТАЙ"=>"39", "КОКОСОВЫЕ (КИЛИНГ) ОСТРОВА"=>"42", "КОЛУМБИЯ"=>"43", "КОНГО"=>"45", "КОНГО, ДЕМОКРАТИЧЕСКАЯ РЕСПУБЛИКА"=>"46", "КОРЕЯ, НАРОДНО-ДЕМОКРАТИЧЕСКАЯ РЕСПУБЛИКА"=>"105", "КОРЕЯ, РЕСПУБЛИКА"=>"106", "КОСТА-РИКА"=>"48", "КОТ Д`ИВУАР"=>"99", "КУБА"=>"50", "КУВЕЙТ"=>"107", "ЛАОССКАЯ НАРОДНО-ДЕМОКРАТИЧЕСКАЯ РЕСПУБЛИКА"=>"109", "ЛАТВИЯ"=>"112", "ЛЕСОТО"=>"111", "ЛИБЕРИЯ"=>"113", "ЛИВАН"=>"110", "ЛИВИЙСКАЯ АРАБСКАЯ ДЖАМАХИРИЯ"=>"114", "ЛИТВА"=>"116", "ЛИХТЕНШТЕЙН"=>"115", "ЛЮКСЕМБУРГ"=>"117", "МАВРИКИЙ"=>"126", "МАВРИТАНИЯ"=>"125", "МАДАГАСКАР"=>"118", "МАЙОТТА"=>"44", "МАКЕДОНИЯ"=>"232", "МАЛАВИ"=>"119", "МАЛАЙЗИЯ"=>"120", "МАЛИ"=>"122", "МАЛЫЕ ТИХООКЕАНСКИЕ ОТДАЛЕННЫЕ ОСТРОВА СОЕДИНЕННЫХ ШТАТОВ"=>"149", "МАЛЬДИВЫ"=>"121", "МАЛЬТА"=>"123", "МАРОККО"=>"132", "МАРТИНИКА"=>"124", "МАРШАЛЛОВЫ ОСТРОВА"=>"151", "МЕКСИКА"=>"127", "МИКРОНЕЗИЯ, ФЕДЕРАТИВНЫЕ ШТАТЫ"=>"150", "МОЗАМБИК"=>"133", "МОЛДОВА, РЕСПУБЛИКА"=>"130", "МОНАКО"=>"128", "МОНГОЛИЯ"=>"129", "МОНТСЕРРАТ"=>"131", "МЬЯНМА"=>"27", "НАМИБИЯ"=>"135", "НАУРУ"=>"136", "Не определено"=>"237", "НЕПАЛ"=>"235", "НИГЕР"=>"144", "НИГЕРИЯ"=>"145", "НИДЕРЛАНДСКИЕ АНТИЛЫ"=>"138", "НИДЕРЛАНДЫ"=>"137", "НИКАРАГУА"=>"143", "НОВАЯ ЗЕЛАНДИЯ"=>"142", "НОВАЯ КАЛЕДОНИЯ"=>"140", "НОРВЕГИЯ"=>"147", "ОБЪЕДИНЕННЫЕ АРАБСКИЕ ЭМИРАТЫ"=>"202", "ОМАН"=>"134", "ОСТРОВ БУВЕ"=>"19", "ОСТРОВ МЭН"=>"214", "ОСТРОВ НОРФОЛК"=>"146", "ОСТРОВ РОЖДЕСТВА"=>"41", "ОСТРОВ ХЕРД И ОСТРОВА МАКДОНАЛЬД"=>"87", "ОСТРОВА КАЙМАН"=>"34", "ОСТРОВА КУКА"=>"47", "ОСТРОВА ТЕРКС И КАЙКОС"=>"206", "ПАКИСТАН"=>"153", "ПАЛАУ"=>"152", "ПАЛЕСТИНА"=>"233", "ПАНАМА"=>"154", "ПАПСКИЙ ПРЕСТОЛ (ГОСУДАРСТВО-ГОРОД ВАТИКАН)"=>"88", "ПАПУА-НОВАЯ ГВИНЕЯ"=>"155", "ПАРАГВАЙ"=>"156", "ПЕРУ"=>"157", "ПИТКЕРН"=>"159", "ПОЛЬША"=>"160", "ПОРТУГАЛИЯ"=>"161", "ПУЭРТО-РИКО"=>"163", "РЕЮНЬОН"=>"165", "Российская Федерация"=>"1", "РУАНДА"=>"166", "РУМЫНИЯ"=>"227", "САН-МАРИНО"=>"174", "САН-ТОМЕ И ПРИНСИПИ"=>"175", "САУДОВСКАЯ АРАВИЯ"=>"176", "СВАЗИЛЕНД"=>"192", "СЕВЕРНЫЕ МАРИАНСКИЕ ОСТРОВА"=>"148", "СЕЙШЕЛЫ"=>"179", "СЕН-БАРТЕЛЕМИ"=>"167", "СЕНЕГАЛ"=>"177", "СЕН-МАРТЕН"=>"171", "СЕНТ-ВИНСЕНТ И ГРЕНАДИНЫ"=>"173", "СЕНТ-КИТС И НЕВИС"=>"168", "СЕНТ-ЛЮСИЯ"=>"170", "СЕНТ-ПЬЕР И МИКЕЛОН"=>"172", "СЕРБИЯ"=>"178", "СИНГАПУР"=>"181", "СИРИЙСКАЯ АРАБСКАЯ РЕСПУБЛИКА"=>"195", "СЛОВАКИЯ"=>"182", "СЛОВЕНИЯ"=>"184", "СОЕДИНЕННОЕ КОРОЛЕВСТВО"=>"211", "СОЕДИНЕННЫЕ ШТАТЫ"=>"216", "СОЛОМОНОВЫ ОСТРОВА"=>"23", "СОМАЛИ"=>"236", "СУДАН"=>"189", "СУРИНАМ"=>"190", "СЬЕРРА-ЛЕОНЕ"=>"180", "ТАДЖИКИСТАН"=>"196", "ТАИЛАНД"=>"197", "ТАЙВАНЬ (КИТАЙ)"=>"40", "ТАНЗАНИЯ, ОБЪЕДИНЕННАЯ РЕСПУБЛИКА"=>"215", "ТОГО"=>"198", "ТОКЕЛАУ"=>"199", "ТОНГА"=>"200", "ТРИНИДАД И ТОБАГО"=>"201", "ТУВАЛУ"=>"207", "ТУНИС"=>"203", "ТУРКМЕНИЯ"=>"205", "ТУРЦИЯ"=>"204", "УГАНДА"=>"208", "УЗБЕКИСТАН"=>"220", "УКРАИНА"=>"209", "УРУГВАЙ"=>"219", "ФАРЕРСКИЕ ОСТРОВА"=>"62", "ФИЛИППИНЫ"=>"158", "ФИНЛЯНДИЯ"=>"65", "ФОЛКЛЕНДСКИЕ ОСТРОВА (МАЛЬВИНСКИЕ)"=>"63", "ФРАНЦИЯ"=>"67", "ФРАНЦУЗСКАЯ ГВИАНА"=>"68", "ФРАНЦУЗСКАЯ ПОЛИНЕЗИЯ"=>"69", "ФРАНЦУЗСКИЕ ЮЖНЫЕ ТЕРРИТОРИИ"=>"70", "ХОРВАТИЯ"=>"49", "ЦЕНТРАЛЬНО-АФРИКАНСКАЯ РЕСПУБЛИКА"=>"35", "ЧАД"=>"37", "ЧЕРНОГОРИЯ"=>"234", "ЧЕШСКАЯ РЕСПУБЛИКА"=>"52", "ЧИЛИ"=>"38", "ШВЕЙЦАРИЯ"=>"194", "ШВЕЦИЯ"=>"193", "ШПИЦБЕРГЕН И ЯН МАЙЕН"=>"191", "ШРИ-ЛАНКА"=>"36", "ЭКВАДОР"=>"57", "ЭКВАТОРИАЛЬНАЯ ГВИНЕЯ"=>"58", "ЭЛАНДСКИЕ ОСТРОВА"=>"66", "ЭРИТРЕЯ"=>"60", "ЭСТОНИЯ"=>"61", "ЭФИОПИЯ"=>"59", "ЮЖНАЯ АФРИКА"=>"185", "ЮЖНАЯ ДЖОРДЖИЯ И ЮЖНЫЕ САНДВИЧЕВЫ ОСТРОВА"=>"64", "ЮЖНАЯ ОСЕТИЯ"=>"224", "ЯМАЙКА"=>"100", "ЯПОНИЯ"=>"101"}
  end
end
