class Api::DictionariesController < ApplicationController
  def index
    @dictionaries = Dictionary.order(:code)
  end
  
  def show
    @dictionary = Dictionary.find_by_code(params[:id])
  end
end
