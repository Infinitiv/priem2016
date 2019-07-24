class SubjectsController < ApplicationController
  load_and_authorize_resource
  before_action :set_subject, only: [:show, :edit, :update, :destroy]
  before_action :subject_params, only: [:create, :update]
  
  def index
    @subjects = Subject.order(:subject_id)
  end
  
  def show
  end
  
  def new
    @subject = Subject.new
  end
  
  def create
    @subject = Subject.new(subject_params)
    if @subject.save
      redirect_to @subject, notice: 'Subject successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @subject.update(subject_params)
      redirect_to @subject
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @subject.destroy
    redirect_to subjects_path
  end
  
  private
  
  def set_subject
    @subject = Subject.find(params[:id])
  end
  
  def subject_params
    params.require(:subject).permit(:subject_name, :subject_id)
  end
end
