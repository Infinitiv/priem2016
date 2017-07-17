class RequestsController < ApplicationController
  before_action :set_request, only: [:show]
  before_action :set_selects, only: [:new]
  
  def index
    @requests = Request.order(id: :desc).select(:id, :query, :created_at).paginate(:page => params[:page])
  end
  
  def show
    
  end
  
  def new
    @request = Request.new
    @campaigns = Campaign.order(:name)
  end
  
  def create
    case Rails.env
      when 'development' then url = 'priem.edu.ru:8000'
      when 'production' then url = '10.0.1.3:8080'
    end
    method = '/' + params[:request][:query]
    request = !params[:custom_request].empty? ? params[:custom_request] : Request.data(method, params)
    uri = URI.parse('http://' + url + '/import/importservice.svc')
    http = Net::HTTP.new(uri.host, uri.port)
    headers = {'Content-Type' => 'text/xml'}
    response = http.post(uri.path + method, request, headers)
    request = Request.new(query: params[:request][:query], input: request, output: Nokogiri::XML(response.body).to_xml(encoding: 'UTF-8'))

    if request.save
      redirect_to request, notice: 'Request was successfully created.'
    else
      render action: "new"
    end
  end
  
  private
  
  def set_request
    @request = Request.find params[:id]
  end
  
  def set_selects
    @queries = ['checkapplication',
                'delete',
                'delete/result',
                'dictionary',
                'dictionarydetails',
                'import',
                'import/result',
                'validate',
                'institutioninfo']
    @dictionaries = {'Общеобразовательные предметы' => 1,
                     'Уровень образования' => 2,
                     'Уровень олимпиады' => 3,
                     'Статус заявления' => 4,
                     'Пол' => 5,
                     'Основание для оценки' => 6,
                     'Страна' => 7,
                     'Регион' => 8,
                     'Коды направлений подготовки' => 9,
                     'Направления подготовки' => 10,
                     'Тип вступительных испытаний' => 11,
                     'Статус проверки заявлений' => 12,
                     'Статус проверки документа' => 13,
                     'Форма обучения' => 14,
                     'Источник финансирования' => 15,
                     'Сообщения об ошибках' => 17,
                     'Тип диплома' => 18,
                     'Олимпиады' => 19,
                     'Гражданство' => 20,
                     'Тип документа, удостоверяющего личность' => 22,
                     'Группа инвалидности' => 23,
                     'Коды профессий' => 24,
                     'Профессия' => 25,
                     'Коды квалификаций' => 26,
                     'Квалификация' => 27,
                     'Коды специальностей' => 28,
                     'Специальности' => 29,
                     'Вид льготы' => 30,
                     'Тип документа' => 31,
                     'Иностранные языки' => 32,
                     'Тип документа для вступительного испытания ОУ' => 33,
                     'Статус приемной кампании' => 34,
                     'Уровень бюджета' => 35,
                     'Категории индивидуальных достижений' => 36,
                     'Статус апелляции, перепроверки' => 37,
                     'Тип приемной кампании' => 38,
                     'Профили олимпиад' => 39,
                     'Классы олимпиад' => 40,
                     'Тип населенного пункта' => 41,
                     'Тип документа, подтверждающего сиротство' => 42,
                     'Тип диплома в области спорта' => 43,
                     'Тип документа, подтверждающего принадлежность к соотечественникам' => 44}
  end
  
  def requst_params
    params.require(:request).permit(:query, :input, :output, :status, :custor_request)
  end
end