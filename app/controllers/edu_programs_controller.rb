class EduProgramsController < ApplicationController
  before_action :set_edu_program, only: [:show, :edit, :update, :destroy]
  before_action :edu_program_params, only: [:create, :update]
  
  def index
    @edu_programs = EduProgram.order(:code)
  end
  
  def show
  end
  
  def new
    @edu_program = EduProgram.new
  end
  
  def create
    @edu_program = EduProgram.new(edu_program_params)
    if @edu_program.save
      redirect_to @edu_program, notice: 'Edu Program successfully created'
    else
      render action 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @edu_program.update(edu_program_params)
      redirect_to @edu_program
    else
      render action: 'edit'
    end
  end
  
  def destroy
    @edu_program.destroy
    redirect_to edu_programs_path
  end
  
  private
  
  def set_edu_program
    @edu_program = EduProgram.find(params[:id])
  end
  
  def edu_program_params
    params.require(:edu_program).permit(:name, :code)
  end
end