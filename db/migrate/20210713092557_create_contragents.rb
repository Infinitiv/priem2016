class CreateContragents < ActiveRecord::Migration
  def change
    create_table :contragents do |t|
      t.references :entrant_application, index: true, foreign_key: true
      t.string :last_name
      t.string :first_name
      t.string :middle_name
      t.date :birth_date
      t.string :address
      t.string :identity_document_number
      t.string :identity_document_serie
      t.date :identity_document_date
      t.string :identity_document_issuer
      t.string :email
      t.string :phone

      t.timestamps null: false
    end
  end
end
