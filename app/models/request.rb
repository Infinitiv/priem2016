class Request < ActiveRecord::Base
  require 'builder'
#   validates :query, :input, :output, :status, presence: true
  
  def self.data(method, params)
    case method
    when '/dictionary'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
      end
    when '/dictionarydetails'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.GetDictionaryContent do |gdc|
          gdc.DictionaryCode params[:dictionary_number]
        end
      end
    when '/checkapplication'
      application = Application.select(:id, :number, :registration_date).find_by_number(params[:application_number])
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.CheckApp do |ca|
          ca.RegistrationDate application.registration_date
          ca.ApplicationNumber application.number
        end
      end  
    when '/institutioninfo'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
      end
    when '/validate' || '/import'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.PackageData do |pd|
          campaign_info(pd, params) if params[:campaign_info]
	  admission_info(pd, params) if params[:admission_info]
          institution_achievements(pd, params) if params[:institution_achievements]
	  applications(pd, params) if params[:applications]
          recommended_lists(pd, params) if params[:recommended_lists]
          orders_of_admission(pd, params) if params[:orders_of_admission]
        end
      end
    when '/import'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.PackageData do |pd|
          campaign_info(pd, params) if params[:campaign_info]
	  admission_info(pd, params) if params[:admission_info]
          institution_achievements(pd, params) if params[:institution_achievements]
	  applications(pd, params) if params[:applications]
          recommended_lists(pd, params) if params[:recommended_lists]
          orders_of_admission(pd, params) if params[:orders_of_admission]
        end
      end
    when '/delete'
      data = ::Builder::XmlMarkup.new(indent: 2)
      data.Root do |root|
        auth_data(root)
        data.DataForDelete do |pd|
	  applications_del(pd, params) if params[:applications]
        end
      end
    end
  end
  
  def self.auth_data(root)
    auth_data = ::Builder::XmlMarkup.new(indent: 2)
    root.AuthData do |ad|
      ad.Login ENV['LOGIN']
      ad.Pass ENV['PASSWORD']
    end
  end
end
