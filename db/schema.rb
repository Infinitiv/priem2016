# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200703061512) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.integer  "institution_achievement_id"
    t.float    "value",                      default: 0.0
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "attachment_id"
    t.string   "status"
  end

  add_index "achievements", ["attachment_id"], name: "index_achievements_on_attachment_id", using: :btree
  add_index "achievements", ["entrant_application_id"], name: "index_achievements_on_entrant_application_id", using: :btree
  add_index "achievements", ["institution_achievement_id"], name: "index_achievements_on_institution_achievement_id", using: :btree

  create_table "admission_volumes", force: :cascade do |t|
    t.integer  "campaign_id"
    t.integer  "education_level_id"
    t.integer  "direction_id"
    t.integer  "number_budget_o",    default: 0
    t.integer  "number_budget_oz",   default: 0
    t.integer  "number_budget_z",    default: 0
    t.integer  "number_paid_o",      default: 0
    t.integer  "number_paid_oz",     default: 0
    t.integer  "number_paid_z",      default: 0
    t.integer  "number_target_o",    default: 0
    t.integer  "number_target_oz",   default: 0
    t.integer  "number_target_z",    default: 0
    t.integer  "number_quota_o",     default: 0
    t.integer  "number_quota_oz",    default: 0
    t.integer  "number_quota_z",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admission_volumes", ["campaign_id"], name: "index_admission_volumes_on_campaign_id", using: :btree

  create_table "attachments", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.string   "document_type"
    t.string   "mime_type"
    t.string   "data_hash"
    t.string   "status"
    t.boolean  "merged"
    t.boolean  "template"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "document_id"
    t.string   "filename"
  end

  add_index "attachments", ["entrant_application_id"], name: "index_attachments_on_entrant_application_id", using: :btree

  create_table "benefit_documents", force: :cascade do |t|
    t.integer  "benefit_document_type_id"
    t.string   "benefit_document_series"
    t.string   "benefit_document_number"
    t.date     "benefit_document_date"
    t.string   "benefit_document_organization"
    t.integer  "benefit_type_id"
    t.integer  "entrant_application_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "attachment_id"
    t.string   "status"
  end

  add_index "benefit_documents", ["attachment_id"], name: "index_benefit_documents_on_attachment_id", using: :btree
  add_index "benefit_documents", ["entrant_application_id"], name: "index_benefit_documents_on_entrant_application_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",                   default: ""
    t.integer  "year_start"
    t.integer  "year_end"
    t.integer  "status_id",              default: 1
    t.integer  "campaign_type_id"
    t.integer  "education_forms",                     array: true
    t.integer  "education_levels",                    array: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "google_key_development"
    t.string   "google_key_production"
  end

  create_table "competitive_group_items", force: :cascade do |t|
    t.integer  "competitive_group_id"
    t.integer  "number_budget_o",      default: 0
    t.integer  "number_budget_oz",     default: 0
    t.integer  "number_budget_z",      default: 0
    t.integer  "number_paid_o",        default: 0
    t.integer  "number_paid_oz",       default: 0
    t.integer  "number_paid_z",        default: 0
    t.integer  "number_target_o",      default: 0
    t.integer  "number_target_oz",     default: 0
    t.integer  "number_target_z",      default: 0
    t.integer  "number_quota_o",       default: 0
    t.integer  "number_quota_oz",      default: 0
    t.integer  "number_quota_z",       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "competitive_group_items", ["competitive_group_id"], name: "index_competitive_group_items_on_competitive_group_id", using: :btree

  create_table "competitive_groups", force: :cascade do |t|
    t.integer  "campaign_id"
    t.string   "name",                default: ""
    t.integer  "education_level_id"
    t.integer  "education_source_id"
    t.integer  "education_form_id"
    t.integer  "direction_id"
    t.boolean  "is_for_krym",         default: false
    t.boolean  "is_additional",       default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "last_admission_date"
  end

  add_index "competitive_groups", ["campaign_id"], name: "index_competitive_groups_on_campaign_id", using: :btree

  create_table "competitive_groups_edu_programs", id: false, force: :cascade do |t|
    t.integer "competitive_group_id", null: false
    t.integer "edu_program_id",       null: false
  end

  create_table "competitive_groups_entrance_test_items", id: false, force: :cascade do |t|
    t.integer "competitive_group_id",  null: false
    t.integer "entrance_test_item_id", null: false
  end

  create_table "competitive_groups_entrant_applications", id: false, force: :cascade do |t|
    t.integer "entrant_application_id", null: false
    t.integer "competitive_group_id",   null: false
  end

  create_table "contracts", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.integer  "competitive_group_id"
    t.integer  "attachment_id"
    t.string   "status"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "contracts", ["attachment_id"], name: "index_contracts_on_attachment_id", using: :btree
  add_index "contracts", ["competitive_group_id"], name: "index_contracts_on_competitive_group_id", using: :btree
  add_index "contracts", ["entrant_application_id"], name: "index_contracts_on_entrant_application_id", using: :btree

  create_table "dictionaries", force: :cascade do |t|
    t.string   "name"
    t.integer  "code"
    t.json     "items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "distributed_admission_volumes", force: :cascade do |t|
    t.integer  "admission_volume_id"
    t.integer  "level_budget_id"
    t.integer  "number_budget_o",     default: 0
    t.integer  "number_budget_oz",    default: 0
    t.integer  "number_budget_z",     default: 0
    t.integer  "number_target_o",     default: 0
    t.integer  "number_target_oz",    default: 0
    t.integer  "number_target_z",     default: 0
    t.integer  "number_quota_o",      default: 0
    t.integer  "number_quota_oz",     default: 0
    t.integer  "number_quota_z",      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "distributed_admission_volumes", ["admission_volume_id"], name: "index_distributed_admission_volumes_on_admission_volume_id", using: :btree

  create_table "edu_programs", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "education_documents", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.string   "education_document_type"
    t.string   "education_document_number"
    t.date     "education_document_date"
    t.date     "original_received_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "education_speciality_code", default: ""
    t.integer  "attachment_id"
    t.string   "status"
    t.string   "education_document_issuer"
  end

  add_index "education_documents", ["attachment_id"], name: "index_education_documents_on_attachment_id", using: :btree
  add_index "education_documents", ["entrant_application_id"], name: "index_education_documents_on_entrant_application_id", using: :btree

  create_table "entrance_test_items", force: :cascade do |t|
    t.integer  "entrance_test_type_id",  default: 1
    t.integer  "min_score"
    t.integer  "entrance_test_priority"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "entrant_applications", force: :cascade do |t|
    t.integer  "registration_number"
    t.integer  "application_number"
    t.integer  "campaign_id"
    t.string   "entrant_last_name"
    t.string   "entrant_first_name"
    t.string   "entrant_middle_name"
    t.integer  "gender_id"
    t.date     "birth_date"
    t.integer  "region_id"
    t.string   "email"
    t.date     "registration_date"
    t.boolean  "need_hostel",           default: false
    t.integer  "status_id",             default: 2
    t.integer  "nationality_type_id"
    t.boolean  "special_entrant",       default: false
    t.boolean  "olympionic",            default: false
    t.boolean  "benefit",               default: false
    t.string   "data_hash"
    t.boolean  "checked",               default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "budget_agr"
    t.integer  "paid_agr"
    t.integer  "enrolled"
    t.date     "enrolled_date"
    t.integer  "exeptioned"
    t.date     "exeptioned_date"
    t.integer  "contracts",                             array: true
    t.string   "snils",                 default: ""
    t.date     "return_documents_date"
    t.text     "comment"
    t.integer  "attachment_id"
    t.text     "address"
    t.string   "zip_code"
    t.string   "phone"
    t.text     "special_conditions"
    t.integer  "locked_by"
    t.string   "status"
    t.text     "request"
  end

  add_index "entrant_applications", ["attachment_id"], name: "index_entrant_applications_on_attachment_id", using: :btree

  create_table "entrant_applications_identity_documents", id: false, force: :cascade do |t|
    t.integer "entrant_application_id", null: false
    t.integer "identity_document_id",   null: false
  end

  create_table "entrant_applications_institution_achievements", id: false, force: :cascade do |t|
    t.integer "entrant_application_id",     null: false
    t.integer "institution_achievement_id", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups_users", id: false, force: :cascade do |t|
    t.integer "user_id",  null: false
    t.integer "group_id", null: false
  end

  create_table "identity_documents", force: :cascade do |t|
    t.integer  "identity_document_type"
    t.string   "identity_document_series"
    t.string   "identity_document_number"
    t.date     "identity_document_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "alt_entrant_last_name"
    t.string   "alt_entrant_first_name"
    t.string   "alt_entrant_middle_name"
    t.integer  "entrant_application_id"
    t.integer  "attachment_id"
    t.string   "status"
    t.string   "identity_document_issuer"
  end

  add_index "identity_documents", ["attachment_id"], name: "index_identity_documents_on_attachment_id", using: :btree
  add_index "identity_documents", ["entrant_application_id"], name: "index_identity_documents_on_entrant_application_id", using: :btree
  add_index "identity_documents", ["identity_document_type"], name: "index_identity_documents_on_identity_document_type", using: :btree

  create_table "institution_achievements", force: :cascade do |t|
    t.string   "name"
    t.integer  "id_category"
    t.integer  "max_value"
    t.integer  "campaign_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "institution_achievements", ["campaign_id"], name: "index_institution_achievements_on_campaign_id", using: :btree

  create_table "journals", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "entrant_application_id"
    t.string   "method"
    t.string   "value_name"
    t.string   "old_value"
    t.string   "new_value"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "done",                   default: false
  end

  add_index "journals", ["entrant_application_id"], name: "index_journals_on_entrant_application_id", using: :btree
  add_index "journals", ["user_id"], name: "index_journals_on_user_id", using: :btree

  create_table "marks", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.integer  "subject_id"
    t.integer  "value"
    t.string   "form"
    t.date     "checked"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organization_uid",       default: ""
    t.string   "year"
  end

  add_index "marks", ["entrant_application_id"], name: "index_marks_on_entrant_application_id", using: :btree
  add_index "marks", ["subject_id"], name: "index_marks_on_subject_id", using: :btree

  create_table "olympic_documents", force: :cascade do |t|
    t.integer  "benefit_type_id"
    t.integer  "entrant_application_id"
    t.integer  "olympic_id"
    t.integer  "diploma_type_id"
    t.integer  "olympic_profile_id"
    t.integer  "class_number"
    t.string   "olympic_document_series"
    t.string   "olympic_document_number"
    t.date     "olympic_document_date"
    t.integer  "olympic_subject_id"
    t.integer  "ege_subject_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "attachment_id"
    t.string   "status"
    t.integer  "olympic_document_type_id"
  end

  add_index "olympic_documents", ["attachment_id"], name: "index_olympic_documents_on_attachment_id", using: :btree
  add_index "olympic_documents", ["entrant_application_id"], name: "index_olympic_documents_on_entrant_application_id", using: :btree

  create_table "other_documents", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.string   "other_document_series"
    t.string   "other_document_number"
    t.date     "other_document_date"
    t.string   "other_document_issuer"
    t.integer  "attachment_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "name"
  end

  add_index "other_documents", ["attachment_id"], name: "index_other_documents_on_attachment_id", using: :btree
  add_index "other_documents", ["entrant_application_id"], name: "index_other_documents_on_entrant_application_id", using: :btree

  create_table "requests", force: :cascade do |t|
    t.string   "query"
    t.text     "input"
    t.text     "output"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.integer  "subject_id"
    t.string   "subject_name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "target_contracts", force: :cascade do |t|
    t.integer  "entrant_application_id"
    t.integer  "competitive_group_id"
    t.integer  "target_organization_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "attachment_id"
    t.string   "status"
  end

  add_index "target_contracts", ["attachment_id"], name: "index_target_contracts_on_attachment_id", using: :btree
  add_index "target_contracts", ["competitive_group_id"], name: "index_target_contracts_on_competitive_group_id", using: :btree
  add_index "target_contracts", ["entrant_application_id"], name: "index_target_contracts_on_entrant_application_id", using: :btree
  add_index "target_contracts", ["target_organization_id"], name: "index_target_contracts_on_target_organization_id", using: :btree

  create_table "target_numbers", force: :cascade do |t|
    t.integer  "target_organization_id"
    t.integer  "competitive_group_id"
    t.integer  "number_target_o",        default: 0
    t.integer  "number_target_oz",       default: 0
    t.integer  "number_target_z",        default: 0
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "target_numbers", ["competitive_group_id"], name: "index_target_numbers_on_competitive_group_id", using: :btree
  add_index "target_numbers", ["target_organization_id"], name: "index_target_numbers_on_target_organization_id", using: :btree

  create_table "target_organizations", force: :cascade do |t|
    t.string   "target_organization_name", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "region_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",              default: "", null: false
    t.string   "encrypted_password", default: "", null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  add_foreign_key "achievements", "attachments"
  add_foreign_key "achievements", "entrant_applications"
  add_foreign_key "achievements", "institution_achievements"
  add_foreign_key "attachments", "entrant_applications"
  add_foreign_key "benefit_documents", "attachments"
  add_foreign_key "benefit_documents", "entrant_applications"
  add_foreign_key "contracts", "attachments"
  add_foreign_key "contracts", "competitive_groups"
  add_foreign_key "contracts", "entrant_applications"
  add_foreign_key "education_documents", "attachments"
  add_foreign_key "entrant_applications", "attachments"
  add_foreign_key "identity_documents", "attachments"
  add_foreign_key "identity_documents", "entrant_applications"
  add_foreign_key "journals", "entrant_applications"
  add_foreign_key "journals", "users"
  add_foreign_key "olympic_documents", "attachments"
  add_foreign_key "olympic_documents", "entrant_applications"
  add_foreign_key "other_documents", "attachments"
  add_foreign_key "other_documents", "entrant_applications"
  add_foreign_key "target_contracts", "attachments"
  add_foreign_key "target_contracts", "competitive_groups"
  add_foreign_key "target_contracts", "entrant_applications"
  add_foreign_key "target_contracts", "target_organizations"
  add_foreign_key "target_numbers", "competitive_groups"
  add_foreign_key "target_numbers", "target_organizations"
end
