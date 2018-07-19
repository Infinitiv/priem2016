class AddEducationSpecialityCodeToEducationDocument < ActiveRecord::Migration
  def change
    add_column :education_documents, :education_speciality_code, :string, default: ''
  end
end
