class Api::DictionariesController < ApplicationController
  def index
    @dictionaries = Dictionary.order(:code)
  end
end