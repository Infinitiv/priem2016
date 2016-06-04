class RequestsController < ApplicationController
  before_action :set_request, only: [:show]
  before_action :set_queries, only: [:new]
  
  def index
    @requests = Request.order(id: :desc).select(:id, :query, :created_at).paginate(:page => params[:page])
  end
  
  def show
    
  end
  
  def new
    @request = Request.new
  end
  
  def create
    params[:request][:campaign_id] = Campaign.last.id
    case Rails.env
      when 'development' then url = 'priem.edu.ru:8000'
      when 'production' then url = '127.0.0.1:8080'
    end
    method = '/' + params[:request][:query]
    request = !params[:custom_request].empty? ? params[:custom_request] : Request.data(method, params)
    uri = URI.parse('http://' + url + '/import/importservice.svc')
    http = Net::HTTP.new(uri.host, uri.port)
    headers = {'Content-Type' => 'text/xml'}
    response = http.post(uri.path + method, request, headers)
    request = Request.new(query: params[:request][:query], input: request, output: response.body)

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
  
  def set_queries
    @queries = ['checkapplication',
                'delete',
                'delete/result',
                'dictionary',
                'dictionarydetails',
                'import',
                'import/result',
                'validate',
                'institutioninfo']
  end
end